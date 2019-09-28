function ed_model(ed_system, optimizer, step::Int64=1)

    m = JuMP.Model(optimizer)

    #Time Information
    time_periods = PowerSystems.get_forecasts_horizon(ed_system)
    time_periods_set = 1:time_periods
    data_first_step = PowerSystems.get_forecast_initial_times(ed_system)[step]
    minutes_per_period = Dates.Minute(PowerSystems.get_forecasts_resolution(ed_system))/Dates.Minute(1)

    # Thermal Generation
    thermal_generators = PowerSystems.get_components(PowerSystems.ThermalStandard, ed_system)
    gen_pwl_points = Dict(PowerSystems.get_name(g) => 1:length(g.op_cost.variable) for g in thermal_generators)
    thermal_gen_names = [PowerSystems.get_name(g) for g in thermal_generators]

    JuMP.@variable(m, cg[thermal_gen_names,time_periods_set])
    JuMP.@variable(m, pg[thermal_gen_names,time_periods_set] >= 0)
    JuMP.@variable(m, rg[thermal_gen_names,time_periods_set] >= 0)
    JuMP.@variable(m, ug[thermal_gen_names,time_periods_set] >= 0)
    JuMP.@variable(m, slack_gen[time_periods_set] >= 0)
    JuMP.@variable(m, slack_load[time_periods_set] >= 0)
    JuMP.@variable(m, 0 <= lambda_lg[g in thermal_gen_names, gen_pwl_points[g], time_periods_set] <= 1);

    # Renewable Generation
    renewable_forecasts = PowerSystems.get_component_forecasts(PowerSystems.RenewableDispatch, ed_system, data_first_step)
    renewable_gen_names = PowerSystems.get_forecast_component_name.(renewable_forecasts)
    JuMP.@variable(m, pw[renewable_gen_names,time_periods_set] >= 0)

    # Loads
    fix_load_forecasts =  PowerSystems.get_component_forecasts(PowerSystems.PowerLoad, ed_system, data_first_step)

    interruptible_load_forecasts =  PowerSystems.get_component_forecasts(PowerSystems.InterruptibleLoad, ed_system, data_first_step)
    interruptible_load_names = PowerSystems.get_forecast_component_name.(interruptible_load_forecasts)
    JuMP.@variable(m, pl[interruptible_load_names, time_periods_set] >= 0)

    JuMP.@objective(m, Min,
    sum(
        sum(cg[PowerSystems.get_name(g),t] + (PowerSystems.get_op_cost(g) |> PowerSystems.get_fixed )*ug[PowerSystems.get_name(g),t] for g in thermal_generators) + 1e6*(slack_gen[t] + slack_load[t])
       - sum(PowerSystems.get_component(il).op_cost.variable.cost[2]*pl[PowerSystems.get_forecast_component_name(il), t] for il in interruptible_load_forecasts)
       - sum(pw[PowerSystems.get_forecast_component_name(ren), t] for ren in renewable_forecasts)
        for t in time_periods_set)
        )

    # Constraints for first time period that require initial conditions
    for g in thermal_generators
        name = PowerSystems.get_name(g)
        power_output_t0 = PowerSystems.get_activepower(g)
        unit_on_t0 = 1.0*(power_output_t0 > 0)
        activepowerlimits = PowerSystems.get_tech(g) |> PowerSystems.get_activepowerlimits
        time_minimum = PowerSystems.get_tech(g) |> PowerSystems.get_timelimits
        ramplimits = PowerSystems.get_tech(g) |> PowerSystems.get_ramplimits

        # Ramp Constraints
        #JuMP.@constraint(m, pg[name,1] + rg[name,1] - unit_on_t0*(power_output_t0 - activepowerlimits.min) <= ramplimits.up*minutes_per_period)

        #JuMP.@constraint(m, unit_on_t0*(power_output_t0 - activepowerlimits.min) - pg[name,1] <= ramplimits.down*minutes_per_period)

    end


    #Remaning Constraints.

    for t in time_periods_set

        JuMP.@constraint(m,
            sum( pg[PowerSystems.get_name(g),t] + g.tech.activepowerlimits.min*ug[PowerSystems.get_name(g),t] for g in thermal_generators) +
            sum( pw[PowerSystems.get_forecast_component_name(g),t] for g in renewable_forecasts) + slack_gen[t]
            == sum(PowerSystems.get_component(load).maxactivepower*PowerSystems.get_forecast_value(load, t) for load in fix_load_forecasts) + sum(pl[PowerSystems.get_forecast_component_name(l),t] for l in interruptible_load_forecasts) + slack_load[t]
        )

        for il in interruptible_load_forecasts
            load_value = PowerSystems.get_component(il).maxactivepower*PowerSystems.get_forecast_value(il, t)
            JuMP.set_upper_bound(pl[PowerSystems.get_forecast_component_name(il), t], load_value)
        end

        for reserve in PowerSystems.get_component_forecasts(PowerSystems.StaticReserve, ed_system, data_first_step)
            JuMP.@constraint(m, sum(rg[name,t] for name in thermal_gen_names) >= PowerSystems.get_component(reserve).requirement*PowerSystems.get_forecast_value(reserve, t)) # (3)
        end

         for g in thermal_generators
            name = PowerSystems.get_name(g)
            power_output_t0 = PowerSystems.get_activepower(g)
            unit_on_t0 = 1.0*(power_output_t0 > 0)
            activepowerlimits = PowerSystems.get_tech(g) |> PowerSystems.get_activepowerlimits
            time_minimum = PowerSystems.get_tech(g) |> PowerSystems.get_timelimits
            ramplimits = PowerSystems.get_tech(g) |> PowerSystems.get_ramplimits
            piecewise_production = PowerSystems.get_op_cost(g) |> PowerSystems.get_variable

            #JuMP.@constraint(m, pg[name,t] + rg[name,t] - pg[name,t-1] <= ramplimits.up*minutes_per_period) # (19)
            if t > 1
                JuMP.@constraint(m, pg[name,t] - pg[name,t-1] <= ramplimits.up*minutes_per_period) # (19)
                JuMP.@constraint(m, pg[name,t-1] - pg[name,t] <= ramplimits.down*minutes_per_period) # (20)
            end

            JuMP.@constraint(m, pg[name,t] + rg[name,t] <= (activepowerlimits.max - activepowerlimits.min)*ug[name,t])

            JuMP.@constraint(m, pg[name,t] == sum((piecewise_production[l][1] - piecewise_production[1][1])*lambda_lg[name,l,t] for l in gen_pwl_points[name])) # (21)
            JuMP.@constraint(m, cg[name,t] == sum((piecewise_production[l][2] - piecewise_production[1][2])*lambda_lg[name,l,t] for l in gen_pwl_points[name])) # (22)
            JuMP.@constraint(m, ug[name,t] == sum(lambda_lg[name,l,t] for l in gen_pwl_points[name])) # (23)
        end

        for rgen in renewable_forecasts
            name = PowerSystems.get_forecast_component_name(rgen)
            ub = rgen.component.tech.rating*PowerSystems.get_forecast_value(rgen,t)
            JuMP.set_upper_bound(pw[name,t], ub)
        end

    end

    return m

end

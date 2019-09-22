function suc_model(suc_system, optimizer, step::Int64=1)

    m = JuMP.Model(optimizer)
    #Time Information
    time_periods = PowerSystems.get_forecasts_horizon(suc_system)
    time_periods_set = 1:time_periods
    data_first_step = PowerSystems.get_forecast_initial_times(suc_system)[step]
    renewable_forecast_sample = first(PowerSystems.get_component_forecasts(PowerSystems.RenewableDispatch, suc_system, data_first_step))
    scenario_count = renewable_forecast_sample.scenario_count
    scenario_set = 1:scenario_count
    minutes_per_period = Dates.Minute(PowerSystems.get_forecasts_resolution(suc_system))/Dates.Minute(1)

    # Thermal Generation
    thermal_generators = PowerSystems.get_components(PowerSystems.ThermalStandard, suc_system)
    gen_pwl_points = Dict(PowerSystems.get_name(g) => 1:length(g.op_cost.variable) for g in thermal_generators)
    thermal_gen_names = [PowerSystems.get_name(g) for g in thermal_generators]

    JuMP.@variable(m, cg[scenario_set, thermal_gen_names,time_periods_set])
    JuMP.@variable(m, pg[scenario_set, thermal_gen_names,time_periods_set] >= 0)
    JuMP.@variable(m, rg[scenario_set, thermal_gen_names,time_periods_set] >= 0)
    JuMP.@variable(m, ug[thermal_gen_names,time_periods_set], binary=true)
    JuMP.@variable(m, vg[thermal_gen_names,time_periods_set], binary=true)
    JuMP.@variable(m, wg[thermal_gen_names,time_periods_set], binary=true)
    JuMP.@variable(m, 0 <= lambda_lg[scenario_set, g in thermal_gen_names, gen_pwl_points[g], time_periods_set] <= 1)

    # Renewable Generation
    renewable_forecasts = PowerSystems.get_component_forecasts(PowerSystems.RenewableDispatch, suc_system, data_first_step)
    renewable_gen_names = PowerSystems.get_forecast_component_name.(renewable_forecasts)
    JuMP.@variable(m, pw[scenario_set, renewable_gen_names,time_periods_set] >= 0)

    # Loads
    fix_load_forecasts =  PowerSystems.get_component_forecasts(PowerSystems.PowerLoad, suc_system, data_first_step)

    interruptible_load_forecasts =  PowerSystems.get_component_forecasts(PowerSystems.InterruptibleLoad, suc_system, data_first_step)
    interruptible_load_names = PowerSystems.get_forecast_component_name.(interruptible_load_forecasts)
    JuMP.@variable(m, pl[scenario_set, interruptible_load_names, time_periods_set] >= 0)

    #Objective
    JuMP.@objective(m, Min,
    sum(
        sum(
        (PowerSystems.get_op_cost(g) |> PowerSystems.get_fixed )*ug[PowerSystems.get_name(g),t] +
        (PowerSystems.get_op_cost(g) |> PowerSystems.get_startup )*vg[PowerSystems.get_name(g),t] +
        1/scenario_count*
            sum(
                cg[s, PowerSystems.get_name(g),t] -
                5000*sum(PowerSystems.get_component(il).op_cost.variable.cost[2]*pl[s, PowerSystems.get_forecast_component_name(il), t] for il in interruptible_load_forecasts) -
                5000*sum(pw[s, PowerSystems.get_forecast_component_name(ren), t] for ren in renewable_forecasts)
            for s in scenario_set)
        for g in thermal_generators)
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

        #Commitment Constraints
        if unit_on_t0 > 0
            JuMP.@constraint(m, sum( (ug[name,t]-1) for t in 1:min(time_periods, time_minimum.up - 999.0) ) == 0)
        else
           JuMP.@constraint(m, sum( ug[name,t] for t in 1:min(time_periods, time_minimum.down - 999.0) ) == 0)
        end

        JuMP.@constraint(m, ug[name,1] - unit_on_t0 == vg[name,1] - wg[name,1])

        for s in scenario_set
            # Ramp Constraints
            JuMP.@constraint(m, pg[s, name,1] + rg[s, name,1] - unit_on_t0*(power_output_t0 - activepowerlimits.min) <= ramplimits.up*minutes_per_period)

            JuMP.@constraint(m, unit_on_t0*(power_output_t0 - activepowerlimits.min) - pg[s, name,1] <= ramplimits.down*minutes_per_period)
        end

        # Shut Down Ramp constraint.
        JuMP.@constraint(m, unit_on_t0*(power_output_t0 - activepowerlimits.min) <= unit_on_t0*(activepowerlimits.max - activepowerlimits.min) - max(0, activepowerlimits.max - ramplimits.down*minutes_per_period)*wg[name,1])

    end


    for t in time_periods_set
        for s in scenario_set
            # Energy Balance Constraint
            JuMP.@constraint(m,
                sum( pg[s, PowerSystems.get_name(g),t] + g.tech.activepowerlimits.min*ug[PowerSystems.get_name(g),t] for g in thermal_generators) +
                sum( pw[s, PowerSystems.get_forecast_component_name(g),t] for g in renewable_forecasts)
                == sum(PowerSystems.get_component(load).maxactivepower*PowerSystems.get_forecast_value(load, t) for load in fix_load_forecasts) +
                sum(pl[s, PowerSystems.get_forecast_component_name(l),t] for l in interruptible_load_forecasts)
            )
        end

        # InterruptibleLoad Upper Bound
        for il in interruptible_load_forecasts, s in scenario_set
            load_value = PowerSystems.get_component(il).maxactivepower*PowerSystems.get_forecast_value(il, t)
            JuMP.set_upper_bound(pl[s, PowerSystems.get_forecast_component_name(il), t], load_value)
        end

        for reserve in PowerSystems.get_component_forecasts(PowerSystems.StaticReserve, suc_system, data_first_step), s in scenario_set
            JuMP.@constraint(m, sum(rg[s, PowerSystems.get_name(g), t] for g in thermal_generators) >= PowerSystems.get_component(reserve).requirement*PowerSystems.get_forecast_value(reserve, t)) # (3)
        end

         for g in thermal_generators
            name = PowerSystems.get_name(g)
            power_output_t0 = PowerSystems.get_activepower(g)
            unit_on_t0 = 1.0*(power_output_t0 > 0)
            activepowerlimits = PowerSystems.get_tech(g) |> PowerSystems.get_activepowerlimits
            time_minimum = PowerSystems.get_tech(g) |> PowerSystems.get_timelimits
            ramplimits = PowerSystems.get_tech(g) |> PowerSystems.get_ramplimits
            piecewise_production = PowerSystems.get_op_cost(g) |> PowerSystems.get_variable


            if t > 1
                JuMP.@constraint(m, ug[name,t] - ug[name,t-1] == vg[name,t] - wg[name,t]) # (12)
                for s in scenario_set
                    JuMP.@constraint(m, pg[s, name,t] + rg[s, name,t] - pg[s, name,t-1] <= ramplimits.up*minutes_per_period) # (19)
                    JuMP.@constraint(m, pg[s, name,t-1] - pg[s, name,t] <= ramplimits.down*minutes_per_period) # (20)
                end
            end

           if t >= time_minimum.up || t == time_periods
                JuMP.@constraint(m, sum( vg[name,t2] for t2 in (t-min(time_minimum.up,time_periods)+1):t) <= ug[name,t])  # (13)
            end

            if t >= time_minimum.down || t == time_periods
                JuMP.@constraint(m, sum( wg[name,t2] for t2 in (t-min(time_minimum.down,time_periods)+1):t) <= 1 - ug[name,t])  # (14)
            end

            #Shut down and Start up ramps are 3x faster than regular ramps.
            for s in scenario_set
                JuMP.@constraint(m, pg[s, name,t] + rg[s, name,t] <= (activepowerlimits.max - activepowerlimits.min)*ug[name,t] - max(0, (activepowerlimits.max - 3*ramplimits.up*minutes_per_period))*vg[name,t]) # (17)

                if t < time_periods
                    JuMP.@constraint(m, pg[s, name,t] + rg[s, name,t] <= (activepowerlimits.max - activepowerlimits.min)*ug[name,t]  - max(0, (activepowerlimits.max - 3*ramplimits.down*minutes_per_period))*wg[name,t+1]) # (18)
                end

                JuMP.@constraint(m, pg[s, name,t] == sum((piecewise_production[l][1] - piecewise_production[1][1])*lambda_lg[s, name,l,t] for l in gen_pwl_points[name])) # (21)
                JuMP.@constraint(m, cg[s, name,t] == sum((piecewise_production[l][2] - piecewise_production[1][2])*lambda_lg[s, name,l,t] for l in gen_pwl_points[name])) # (22)
                JuMP.@constraint(m, ug[name,t] == sum(lambda_lg[s, name,l,t] for l in gen_pwl_points[name])) # (23)

            end
        end

        for rgen in renewable_forecasts
            name = PowerSystems.get_forecast_component_name(rgen)
            ub = rgen.component.tech.rating*PowerSystems.get_forecast_value(rgen,t)
            for s in scenario_set
                JuMP.set_upper_bound(pw[s, name, t], ub[s])
            end
        end

    end

    return m

end

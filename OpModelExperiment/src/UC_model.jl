using JuMP


data_first_step = PSY.get_forecasts_initial_time(system)
thermal_generators = get_components(ThermalStandard, system)
renewable_generators = get_components(RenewableGen, system)
renewable_dispatch_forecasts = PSY.get_component_forecasts(RenewableDispatch, system, data_first_step)
renewable_fix_forecasts = PSY.get_component_forecasts(RenewableFix, system, data_first_step)
hydro_generators = get_components(HydroGen, system)
hydro_forecasts = PSY.get_component_forecasts(HydroDispatch, system, data_first_step)

thermal_gen_set = [get_name(g) for g in thermal_generators]
renewable_gen_set = [get_name(g) for g in renewable_generators]
vcat(renewable_gen_set, get_name.(hydro_generators))

time_periods = get_forecasts_horizon(system)
time_periods_set = 1:time_periods
gen_pwl_points = Dict(get_name(g) => 1:length(g.op_cost.variable) for g in thermal_generators)

load_forecasts = PSY.get_component_forecasts(PowerLoad, system, data_first_step)

m = Model()

@variable(m, cg[thermal_gen_set,time_periods_set])
@variable(m, pg[thermal_gen_set,time_periods_set] >= 0)
@variable(m, pw[renewable_gen_set,time_periods_set] >= 0)
@variable(m, rg[thermal_gen_set,time_periods_set] >= 0)
@variable(m, ug[thermal_gen_set,time_periods_set], binary=true)
@variable(m, vg[thermal_gen_set,time_periods_set], binary=true)
@variable(m, wg[thermal_gen_set,time_periods_set], binary=true)
@variable(m, 0 <= lambda_lg[g in thermal_gen_set, gen_pwl_points[g], time_periods_set] <= 1)


@objective(m, Min,
    sum(
        sum(
            cg[get_name(g),t] + (get_op_cost(g) |> get_fixed )*ug[get_name(g),t]
        for t in time_periods_set)
    for g in thermal_generators)
) # (1)

# All constraints for first time period
for g in thermal_generators
    name = get_name(g)
    power_output_t0 = get_activepower(g)
    unit_on_t0 = 1.0*(power_output_t0 > 0)
    activepowerlimits = get_tech(g) |> get_activepowerlimits
    time_minimum = get_tech(g) |> get_timelimits
    ramplimits = get_tech(g) |> get_ramplimits


    if unit_on_t0 > 0
        @constraint(m, sum( (ug[name,t]-1) for t in 1:min(time_periods, time_minimum.up - 999.0) ) == 0) # (4)
    else
        @constraint(m, sum( ug[name,t] for t in 1:min(time_periods, time_minimum.down - 999.0) ) == 0) # (5)
    end

    @constraint(m, ug[name,1] - unit_on_t0 == vg[name,1] - wg[name,1]) # (6)

    @constraint(m, pg[name,1] + rg[name,1] - unit_on_t0*(power_output_t0 - activepowerlimits.min) <= ramplimits.up) # (8)
    @constraint(m, unit_on_t0*(power_output_t0 - activepowerlimits.min) - pg[name,1] <= ramplimits.down) # (9)
    @constraint(m, unit_on_t0*(power_output_t0 - activepowerlimits.min) <= unit_on_t0*(activepowerlimits.max - activepowerlimits.min) - max(0, activepowerlimits.max - ramplimits.down)*wg[name,1]) # (10)
end

for t in time_periods_set

    @constraint(m,
        sum( pg[get_name(g),t] + g.activepowerlimits.min*ug[get_name(g),t] for g in thermal_generators) +
        sum( pw[get_name(g),t] for g in renewable_generators)
        == data["demand"][t]
    ) # (2)

    @constraint(m, sum(rg[name,t] for g in thermal_gen_set) >= data["reserves"][t]) # (3)

    for g in thermal_generators
        name = get_name(g)
        power_output_t0 = get_activepower(g)
        unit_on_t0 = 1.0*(power_output_t0 > 0)
        activepowerlimits = get_tech(g) |> get_activepowerlimits
        time_minimum = get_tech(g) |> get_timelimits
        ramplimits = get_tech(g) |> get_ramplimits

        if t > 1
            @constraint(m, ug[name,t] - ug[name,t-1] == vg[name,t] - wg[name,t]) # (12)
            @constraint(m, pg[name,t] + rg[name,t] - pg[name,t-1] <= ramplimits.up) # (19)
            @constraint(m, pg[name,t-1] - pg[name,t] <= ramplimits.down) # (20)
        end


        if t >= time_minimum.up || t == time_periods
            @constraint(m, sum( vg[name,t2] for t2 in (t-min(time_minimum.up,time_periods)+1):t) <= ug[name,t])  # (13)
        end

        if t >= time_minimum.down || t == time_periods
            @constraint(m, sum( wg[name,t2] for t2 in (t-min(time_minimum.down,time_periods)+1):t) <= 1 - ug[name,t])  # (14)
        end

        @constraint(m, pg[name,t] + rg[name,t] <= (activepowerlimits.max - activepowerlimits.min)*ug[name,t] - max(0, (activepowerlimits.max - ramplimits.up))*vg[name,t]) # (17)

        if t < time_periods
            @constraint(m, pg[name,t] + rg[name,t] <= (activepowerlimits.max - activepowerlimits.min)*ug[name,t] - max(0, (activepowerlimits.max - ramplimits.down))*wg[name,t+1]) # (18)
        end

        @constraint(m, pg[name,t] == sum((gen["piecewise_production"][l]["mw"] - gen["piecewise_production"][1]["mw"])*lambda_lg[name,l,t] for l in gen_pwl_points[g])) # (21)
        @constraint(m, cg[name,t] == sum((gen["piecewise_production"][l]["cost"] - gen["piecewise_production"][1]["cost"])*lambda_lg[name,l,t] for l in gen_pwl_points[g])) # (22)
        @constraint(m, ug[name,t] == sum(lambda_lg[name,l,t] for l in gen_pwl_points[g])) # (23)
    end

# Here we apply the different types of generators instead of a single loop

    for (rg, rgen) in data["renewable_generators"]
        @constraint(m, rgen["power_output_minimum"][t] <= pw[rg,t] <= rgen["power_output_maximum"][t]) # (24)
    end
end


println("optimization")

using Cbc
optimize!(m, with_optimizer(Cbc.Optimizer, logLevel=1))

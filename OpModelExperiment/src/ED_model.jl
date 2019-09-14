using JuMP
using PowerSystems

########################################## Data ############################################

# Getting data for the model.
# Time
time_periods = get_forecasts_horizon(system)
time_periods_set = 1:time_periods
data_first_step = PSY.get_forecasts_initial_time(system)
# Thermal Generation
thermal_generators = get_components(ThermalStandard, system)
thermal_gen_set = [get_name(g) for g in thermal_generators]
gen_pwl_points = Dict(get_name(g) => 1:length(g.op_cost.variable) for g in thermal_generators)
# Renewable Generation
renewable_generators = get_components(RenewableGen, system)
renewable_dispatch_forecasts = PSY.get_component_forecasts(RenewableDispatch, system, data_first_step)
renewable_fix_forecasts = PSY.get_component_forecasts(RenewableFix, system, data_first_step)
hydro_generators = get_components(HydroGen, system)
hydro_forecasts = PSY.get_component_forecasts(HydroDispatch, system, data_first_step)
# The model below makes variables for Hydro and Renewables together.
renewable_gen_set = [get_name(g) for g in renewable_generators]
renewable_gen_set = vcat(renewable_gen_set, get_name.(hydro_generators))
# Load Data
load_forecasts = [3262.31, 3215.96, 3220.9, 3274.01, 3435.74, 3779.83, 4116.21, 4094.34, 4076.64, 4063.94, 4039.37, 4019.19, 3989.72, 3952.9, 3929.59, 3882.41, 3953.81, 4360.68, 4502.07, 4410.01, 4247.12, 3956.0, 3635.45, 3395.44, 3238.06, 3172.24, 3165.48, 3204.1, 3354.96, 3653.88, 3938.94, 3910.58, 3901.01, 3929.77, 3946.27, 3930.95, 3908.78, 3876.46, 3816.22, 3792.84, 3847.59, 4236.29, 4361.67, 4274.07, 4120.71, 3850.28, 3554.75, 3343.47]
# Reserve Data
reserve_time_series =  [97.8693, 96.47879999999999, 96.627, 98.22030000000001, 103.0722, 113.39489999999999, 123.4863, 122.8302, 122.29919999999998, 121.9182, 121.18109999999999, 120.5757, 119.6916, 118.587, 117.8877, 116.47229999999999, 118.6143, 130.8204, 135.0621, 132.3003, 127.41359999999999, 118.67999999999999, 109.06349999999999, 101.86319999999999, 97.14179999999999, 95.1672, 94.9644, 96.12299999999999, 100.6488, 109.6164, 118.1682, 117.31739999999999, 117.0303, 117.89309999999999, 118.3881, 117.92849999999999, 117.2634, 116.29379999999999, 114.4866, 113.7852, 115.4277, 127.08869999999999, 130.8501, 128.22209999999998, 123.62129999999999, 115.5084, 106.6425, 100.30409999999999]

##################################### Optimization Model ###################################
m = Model()

@variable(m, cg[thermal_gen_set,time_periods_set])
@variable(m, pg[thermal_gen_set,time_periods_set] >= 0)
@variable(m, pw[renewable_gen_set,time_periods_set] >= 0)
@variable(m, rg[thermal_gen_set,time_periods_set] >= 0)
@variable(m, 0 <= lambda_lg[g in thermal_gen_set, gen_pwl_points[g], time_periods_set] <= 1)


@objective(m, Min,
    sum(
        sum(cg[get_name(g),t] for t in time_periods_set)
    for g in thermal_generators)
) # (1)

# All constraints for first time period
for g in thermal_generators
    name = get_name(g)
    power_output_t0 = get_activepower(g)
    activepowerlimits = get_tech(g) |> get_activepowerlimits
    ramplimits = get_tech(g) |> get_ramplimits
    piecewise_production = get_op_cost(g) |> get_variable

    @constraint(m, pg[name,1] + rg[name,1] - (power_output_t0 - activepowerlimits.min) <= ramplimits.up)
    @constraint(m, (power_output_t0 - activepowerlimits.min) - pg[name,1] <= ramplimits.down)
end

for t in time_periods_set

    @constraint(m,
        sum( pg[get_name(g),t] + g.activepowerlimits.min for g in thermal_generators) +
        sum( pw[get_name(g),t] for g in renewable_generators)
        == load_forecasts[t]
    ) # (2)

    @constraint(m, sum(rg[name,t] for g in thermal_gen_set) >= reserve_time_series[t])

    for g in thermal_generators
        name = get_name(g)
        power_output_t0 = get_activepower(g)
        unit_on_t0 = 1.0*(power_output_t0 > 0)
        activepowerlimits = get_tech(g) |> get_activepowerlimits
        time_minimum = get_tech(g) |> get_timelimits
        ramplimits = get_tech(g) |> get_ramplimits

        @constraint(m, pg[name,t] + rg[name,t] <= activepowerlimits.max)
        @constraint(m, pg[name,t] >= activepowerlimits.min)

        @constraint(m, pg[name,t] == sum((piecewise_production[l][1] - piecewise_production[1][1])*lambda_lg[name,l,t] for l in gen_pwl_points[g])) # (21)
        @constraint(m, cg[name,t] == sum((piecewise_production[l][2] - piecewise_production[1][2])*lambda_lg[name,l,t] for l in gen_pwl_points[g])) # (22)
        @constraint(m, ug[name,t] == sum(lambda_lg[name,l,t] for l in gen_pwl_points[g])) # (23)
    end

# Here we apply the different types of generators instead of a single loop
    for resource_forecast in [renewable_fix_forecasts, renewable_dispatch_forecasts, hydro_forecasts]
        for rgen in resource_forecast
            name = get_forecast_component_name(rgen)
            ub = rgen.component.tech.rating*get_forecast_value(rgen,t)
            @constraint(m, 0.0 <= pw[name,t] <= ub) # (24)
        end
    end

end


println("optimization")

using Gurobi
optimize!(m, with_optimizer(Gurobi.Optimizer))

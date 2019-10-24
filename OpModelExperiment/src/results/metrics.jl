function total_fuel_cost(experiment_time::String, trial::Int64, day_range, sys::PowerSystems.System)
    result = collect_ed_results(experiment_time, trial, day_range, 24)

    variable_cost = 0.0
    fixed_cost = 0.0
    for n in names(result["cg"])
        variable_cost += sum(result["cg"][!,n])
        g = PowerSystems.get_component(PowerSystems.ThermalStandard, sys, String(n))
        g_fixed_cost = PowerSystems.get_op_cost(g) |> PowerSystems.get_fixed
        fixed_cost += sum(result["ug"][!,n]*g_fixed_cost)
    end

    total_cost = variable_cost + fixed_cost

    return total_cost
end

function total_load_not_supplied(experiment_time::String, trial::Int64, day_range, sys::PowerSystems.System)
    res = collect_ed_results(experiment_time, trial, day_range, 24)
    return aggregate(res["il_ub"] .- res["pl"], sum)[!,1][1]
end

function total_curtailment(experiment_time::String, trial::Int64, day_range, sys::PowerSystems.System)
    res = collect_ed_results(experiment_time, trial,  day_range, 24)
    return aggregate(res["pw_ub"] .- res["pw"], sum)[!,1][1]
end

function total_computing_time(experiment_time::String, trial::Int64, day_range, model::String)
    res = collect_uc_results(experiment_time, model, trial::Int64, day_range)
    return res["optimizer_log"][!,:solve_time]
end

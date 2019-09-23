function remove_forecasts_by_type!(system::PowerSystems.System, ::Type{T}) where T <: PowerSystems.Component

    forecasts_to_delete = Vector()
    for first_step in PowerSystems.get_forecast_initial_times(uc_system)
        for f in PowerSystems.get_component_forecasts(T, uc_system, first_step)
            push!(forecasts_to_delete, f)
        end
    end

    for f in forecasts_to_delete
        PowerSystems.remove_forecast!(uc_system, f)
    end

    return
end

function explore_cost_functions(sys::PSY.System)
    p = plot(legend = :bottomright)
    for t in PowerSystems.get_components(PowerSystems.ThermalStandard, sys)
        plot!([x[2] for x in t.op_cost.variable.cost], [x[1] for x in t.op_cost.variable.cost], label = t.name)
    end
    return(p)
end

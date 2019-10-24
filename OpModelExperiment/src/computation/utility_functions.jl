function solve_JuMPmodel!(JuMPmodel::JuMP.Model, save_path::String; kwargs...)

    timed_log = Dict{Symbol, Any}()

    if JuMPmodel.moi_backend.state == MOIU.NO_OPTIMIZER

        if !(:optimizer in keys(kwargs))
            error("No Optimizer has been defined, can't solve the operational problem")
        end

        _, timed_log[:timed_solve_time],
        timed_log[:solve_bytes_alloc],
        timed_log[:sec_in_gc] = @timed JuMP.optimize!(JuMPmodel,
                                                        kwargs[:optimizer])

    else

        _, timed_log[:timed_solve_time],
        timed_log[:solve_bytes_alloc],
        timed_log[:sec_in_gc] = @timed JuMP.optimize!(JuMPmodel)

    end

    model_status = JuMP.primal_status(JuMPmodel)
    if model_status != MOI.FEASIBLE_POINT::MOI.ResultStatusCode
        error("Status is $(model_status)")
    end

    #creating the results to print to memory
    vars_result = get_model_result(JuMPmodel)
    optimizer_log = get_optimizer_log(JuMPmodel)
    obj_value = Dict(:OBJECTIVE_FUNCTION => JuMP.objective_value(JuMPmodel))
    merge!(optimizer_log, timed_log)

    #results to be printed to memory
    results = Dict(:vars => vars_result,
                   :obj_value => obj_value,
                   :optimizer_log => optimizer_log)

    write_model_results(results, save_path)

    return

end

function make_initial_conditions_from_data(sys::PowerSystems.System)
    inital_conditions = Dict{String, Any}()
    for gen in PowerSystems.get_components(PowerSystems.ThermalStandard, sys)
        ini_g = Dict{Symbol, Float64}()
        name = PowerSystems.get_name(gen)
        ini_g[:power_output_t0] =  PowerSystems.get_activepower(gen)
        activepowerlimits = PowerSystems.get_tech(gen) |> PowerSystems.get_activepowerlimits
        ini_g[:min_power] = activepowerlimits.min
        ini_g[:unit_on_t0] = 1.0*(ini_g[:power_output_t0] > 0)
        ini_g[:time_down_t0] =  999.0*(1.0 - (ini_g[:power_output_t0] > 0))
        ini_g[:time_up_t0] =  999.0*(ini_g[:power_output_t0] > 0)
        inital_conditions[name] = ini_g
    end
    return inital_conditions
end

function update_commitment_status!(ed_model, uc_model, t)

    status_solutions = JuMP.value.(uc_model.obj_dict[:ug])[:,t]
    for (ix ,v) in enumerate(status_solutions)
        name = axes(status_solutions)[1][ix]
        JuMP.fix.(ed_model.obj_dict[:ug][name, :], v; force = true)
    end
    return
end

function update_initial_conditions!(ic, uc_m, ed_m, t)

    pg = ed_m[:pg]
    ug = uc_m[:ug]

    for (k, v) in ic
        #@assert ug[k, t] == 1.0*(JuMP.value(pg[k, t]) > eps())
        v[:power_output_t0] = JuMP.value(pg[k, end]) + JuMP.value(ug[k, t])*v[:min_power]
        # If the unit was on, add to the count
        if v[:unit_on_t0] > 0
            if v[:unit_on_t0] == JuMP.value(ug[k, t])
                v[:time_up_t0] += 1.0
            elseif v[:unit_on_t0] != JuMP.value(ug[k, t])
                v[:time_up_t0] = 0.0
                v[:time_down_t0] = 1.0
            end
            v[:unit_on_t0] = JuMP.value(ug[k, t])
            continue
        end

        # If the unit was off, add to the count
        if v[:unit_on_t0] < 1
            if v[:unit_on_t0] == JuMP.value(ug[k, t])
                v[:time_down_t0] += 1.0
            elseif v[:unit_on_t0] != JuMP.value(ug[k, t])
                v[:time_up_t0] = 1.0
                v[:time_down_t0] = 0.0
            end
            v[:unit_on_t0] = JuMP.value(ug[k, t])
            continue
        end
    end

end

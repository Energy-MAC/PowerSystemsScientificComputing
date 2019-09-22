function _prepare_workspace!(base_name::String, folder::String)

    !isdir(folder) && error("Specified folder is not valid")

    cd(folder)
    global_path = joinpath(folder, "$(base_name)")
    isdir(global_path) && mkpath(global_path)
    simulation_path = joinpath(global_path, "$(round(Dates.now(),Dates.Minute))-$(base_name)")
    raw_ouput = joinpath(simulation_path, "raw_output")
    mkpath(raw_ouput)
    models_json_ouput = joinpath(simulation_path, "models_json")
    mkpath(models_json_ouput)

    return

end

function solve_JuMPmodel!(JuMPmodel::JuMP.Model; kwargs...)

    timed_log = Dict{Symbol, Any}()

    save_path = get(kwargs, :save_path, nothing)

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
    #creating the results to print to memory
    vars_result = get_model_result(JuMPmodel)
    optimizer_log = get_optimizer_log(JuMPmodel)
    time_stamp = get_time_stamp(JuMPmodel)
    obj_value = Dict(:OBJECTIVE_FUNCTION => JuMP.objective_value(JuMPmodel))
    merge!(optimizer_log, timed_log)

    #results to be printed to memory
    results = Dict(:vars => vars_result,
                   :obj_value => obj_value,
                   :optimizer_log => optimizer_log,
                   :time_stamp => time_stamp)

    !isnothing(save_path) && write_model_results(results, save_path)

    return

end

function update_commitment_status!(ed_model, uc_model, t)

    status_solutions = value.(uc_model.obj_dict[:ug])[:,t]
    for (ix ,v) in enumerate(status_solutions)
        name = axes(status_solutions)[1][ix]
        fix.(ed_model.obj_dict[:ug][name, :], v; force = true)
    end

    return
end


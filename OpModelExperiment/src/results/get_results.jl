function _result_dataframe_vars(variable::JuMP.Containers.DenseAxisArray)

    result = Array{Float64, length(variable.axes)}(undef, length(variable.axes[2]), length(variable.axes[1]))
    names = Array{Symbol, 1}(undef, length(variable.axes[1]))

    for t in variable.axes[2], (ix, name) in enumerate(variable.axes[1])
        result[t, ix] = JuMP.value(variable[name, t])
        names[ix] = Symbol(name)
    end

    return DataFrames.DataFrame(result, names)

end

function _result_dataframe_vars(variable::JuMP.Containers.SparseAxisArray)
    return Vector()
end

function get_model_result(m::JuMP.Model)

    results_dict = Dict{Symbol, Any}()

    for (k, v) in m.obj_dict
        results_dict[k] = _result_dataframe_vars(v)
    end

    return results_dict

end

function get_optimizer_log(JuMPmodel::JuMP.Model)

    optimizer_log = Dict{Symbol, Any}()

    optimizer_log[:obj_value] = JuMP.objective_value(JuMPmodel)
    optimizer_log[:termination_status] = JuMP.termination_status(JuMPmodel)
    optimizer_log[:primal_status] = JuMP.primal_status(JuMPmodel)
    optimizer_log[:dual_status] = JuMP.dual_status(JuMPmodel)
    optimizer_log[:solver] =  JuMP.solver_name(JuMPmodel)
    try
        optimizer_log[:solve_time] = MOI.get(JuMPmodel, MOI.SolveTime())
    catch
        @warn("SolveTime() property not supported by $(optimizer_log[:solver])")
        optimizer_log[:solve_time] = "Not Supported by $(optimizer_log[:solver])"
    end
    return optimizer_log
end

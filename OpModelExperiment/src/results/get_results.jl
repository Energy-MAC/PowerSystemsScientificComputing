function _result_dataframe_vars(variable::JuMP.Containers.DenseAxisArray, get_function)

    if length(axes(variable)) == 1
        result = Vector{Float64}(undef, length(first(variable.axes)))

        for t in variable.axes[1]
            result[t] = get_function(variable[t])
        end

        return DataFrames.DataFrame(var = result)

    elseif length(axes(variable)) < 3

        result = Array{Float64, 2}(undef, length(last(variable.axes)), length(first(variable.axes)))
        names = Array{Symbol, 1}(undef, length(variable.axes[1]))

        for t in variable.axes[2], (ix, name) in enumerate(variable.axes[1])
            result[t, ix] = get_function(variable[name, t])
            names[ix] = Symbol(name)
        end

        return DataFrames.DataFrame(result, names)

    elseif length(axes(variable)) == 3
        extra_dims = sum(length(axes(variable)[2:end-1]))
        extra_vars = [Symbol("S$(s)") for s in 1:extra_dims]
        result_df = DataFrames.DataFrame()
        names = vcat(extra_vars, Symbol.(axes(variable)[1]))

        for i in variable.axes[2]
            third_dim = collect(fill(i,size(variable)[end]))
            result = Array{Float64 ,2}(undef, length(last(variable.axes)),
                                              length(first(variable.axes)))
            for t in last(variable.axes), (ix, name) in enumerate(first(variable.axes))
                result[t, ix] = get_function(variable[name, i, t])
            end
            res = DataFrames.DataFrame(hcat(third_dim, result))
            result_df = vcat(result_df, res)
        end

        return DataFrames.names!(result_df, names)

    end

end

function _result_dataframe_vars(variable::JuMP.Containers.SparseAxisArray, get_function)
    return Vector()
end

function get_model_result(m::JuMP.Model)

    results_dict = Dict{Symbol, Any}()

    for (k, v) in m.obj_dict
        results_dict[k] = _result_dataframe_vars(v, JuMP.value)
    end

    results_dict[:pw_ub] = _result_dataframe_vars(m.obj_dict[:pw], JuMP.upper_bound)
    results_dict[:il_ub] = _result_dataframe_vars(m.obj_dict[:pl], JuMP.upper_bound)

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

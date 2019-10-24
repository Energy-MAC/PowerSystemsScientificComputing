function collect_ed_results(experiment_time::String, trial::Int64, day_range, hours::Int64)

    base_path = joinpath(DrWatson.datadir(), "exp_raw", "$(experiment_time)")

    Results = Dict{String, DataFrames.DataFrame}()
    names = ["cg", "pg", "pl", "pw", "rg", "ug", "il_ub", "pw_ub", "optimizer_log"]

    for n in names
        Results[n] = DataFrames.DataFrame()
    end

    for d in day_range, h in 1:hours
        folder = joinpath(base_path, "Trial-$(trial)-ED-Day-$(d)-hour-$(h)")
        for (k, v) in Results
            file_results = Feather.read(joinpath(folder, "$(k).feather"))
            Results[k] = vcat(v, file_results)
        end

    end

    return Results

end

function collect_uc_results(experiment_time::String, model::String, trial::Int64, day_range)

    base_path = joinpath(DrWatson.datadir(), "exp_raw", "$(experiment_time)")

    Results = Dict{String, DataFrames.DataFrame}()
    names = ["cg", "pg", "pl", "pw", "rg", "ug", "il_ub", "pw_ub", "optimizer_log"]

    for n in names
        Results[n] = DataFrames.DataFrame()
    end

    for d in day_range
        folder = joinpath(base_path, "Trial-$(trial)-$(model)-Day-$(d)")
        for (k, v) in Results
            file_results = Feather.read(joinpath(folder, "$(k).feather"))
            Results[k] = vcat(v, file_results)
        end

    end

    return Results

end

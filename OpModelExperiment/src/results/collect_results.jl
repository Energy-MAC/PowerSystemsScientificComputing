function collect_ed_results(dir::AbstractString, days::Int64, hours::Int64)

    Results = Dict{String, DataFrames.DataFrame}()
    names = ["cg", "pg", "pl", "pw", "rg", "ug", "il_ub", "pw_ub", "optimizer_log"]

    for n in names
        Results[n] = DataFrames.DataFrame()
    end

    for d in 1:days, h in 1:hours
        folder = joinpath(dir, "ED-Day-$(d)-hour-$(h)")
        for (k, v) in Results
            file_results = Feather.read(joinpath(folder, "$(k).feather"))
            Results[k] = vcat(v, file_results)
        end

    end

    return Results

end

function collect_uc_results(dir::AbstractString, days::Int64)

    Results = Dict{String, DataFrames.DataFrame}()
    names = ["cg", "pg", "pl", "pw", "rg", "ug", "il_ub", "pw_ub", "optimizer_log"]

    for n in names
        Results[n] = DataFrames.DataFrame()
    end

    for d in 1:days
        folder = joinpath(dir, "UC-Day-$(d)")
        for (k, v) in Results
            file_results = Feather.read(joinpath(folder, "$(k).feather"))
            Results[k] = vcat(v, file_results)
        end

    end

    return Results

end

""" Exports Operational Model Results to a path"""
function write_model_results(results::Dict, save_path::String)

    if !isdir(save_path)
        @error("Specified path is not valid. Run write_results to save results.")
    end

    path = remove_char("$save_path/$(round(Dates.now(),Dates.Minute))", ":")

    new_folder = mkdir(path)
    folder_path = new_folder

    for (k,v) in results[:vars]
        file_path = joinpath(folder_path, "$(k).feather")
        Feather.write(file_path, v)
    end

    write_optimizer_log(results.optimizer_log, folder_path)
    #_write_time_stamps(results.time_stamp, folder_path)
    println("Files written to $folder_path folder.")

    return

end

function write_optimizer_log(optimizer_log::Dict{Symbol, Any}, save_path::AbstractString)

    optimizer_log[:termination_status] = Int(optimizer_log[:termination_status])
    optimizer_log[:primal_status] = Int(optimizer_log[:primal_status])
    optimizer_log[:dual_status] = Int(optimizer_log[:dual_status])
    optimizer_log[:solve_time] = optimizer_log[:solve_time]

    df = DataFrames.DataFrame(optimizer_log)
    file_path = joinpath(save_path,"optimizer_log.feather")
    Feather.write(file_path, df)

    return

end

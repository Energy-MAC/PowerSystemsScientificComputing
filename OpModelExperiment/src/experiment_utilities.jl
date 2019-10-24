function remove_char(s::String, char::String)
    return replace(s, Regex("[$char]") => "")
end

function prepare_workspace!(folder::String)

    !isdir(folder) && error("Specified folder is not valid")

    cd(folder)
    global_path = joinpath(folder)
    isdir(global_path) && mkpath(global_path)
    _sim_path =  remove_char("$(round(Dates.now(),Dates.Minute))", ":")
    simulation_path = joinpath(global_path,)
    raw_ouput = joinpath(simulation_path)
    mkpath(raw_ouput)

    return raw_ouput

end

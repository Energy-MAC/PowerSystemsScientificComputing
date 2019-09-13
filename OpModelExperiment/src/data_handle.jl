using PowerSystems

function obtain_raw_data(base_dir::String, sha::String)
    data_path = joinpath(base_dir,"raw_input_data")
    ispath(data_path) && rm(data_path, recursive = true)
    mkpath(data_path)

    if Sys.iswindows()
        POWERSYSTEMSTESTDATA_URL = "https://github.com/GridMod/RTS-GMLC/archive/$(sha).zip"
    else
        POWERSYSTEMSTESTDATA_URL = "https://github.com/GridMod/RTS-GMLC/archive/$(sha).tar.gz"
    end

    tempfilename= Base.download(POWERSYSTEMSTESTDATA_URL)
    Sys.iswindows() && unzip_windows(tempfilename, base_dir)
    Sys.islinux() && unzip_unix(tempfilename, base_dir)
    Sys.isapple() && unzip_unix(tempfilename, base_dir)

    mv(joinpath(base_dir, "RTS-GMLC-$(sha)"), data_path, force=true)

    return data_path

end

function unzip_unix(filename, directory)
    @assert success(`tar -xvf $filename -C $directory`) "Unable to extract $filename to $directory"
end

function unzip_windows(filename, directory)
    home = (Base.VERSION < v"0.7-") ? JULIA_HOME : Sys.BINDIR
    @assert success(`$home/7z x $filename -y -o$directory`) "Unable to extract $filename to $directory"
end

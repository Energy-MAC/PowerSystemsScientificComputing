using DrWatson
using PowerSystems
using Dates

const PSY = PowerSystems

########################## Get the data for the model #########################
include(joinpath(srcdir(),"data_handle.jl"))
sha = "367916992a15d5fccf6ce23220c4abae1c27de3d"
base_dir = datadir()

RTS_ROOT = obtain_raw_data(base_dir, sha)
RTS_DIR = joinpath(RTS_ROOT,"RTS_Data/SourceData/")

rts_data = PSY.PowerSystemRaw(RTS_DIR,
    100.0,joinpath(RTS_ROOT,"RTS_Data/FormattedData/SIIP/user_descriptors.yaml"))


sys_DA = System(rts_data; forecast_resolution = Dates.Hour(1))
sys_RT = System(rts_data; forecast_resolution = Dates.Minute(5))

###################Convert the data to appropiate Time Series sizes#########################
split_forecasts!(sys_DA,
                get_forecasts(Deterministic, sys_DA, Dates.DateTime("2020-01-01T00:00:00")),
                Dates.Hour(24),
                48)

split_forecasts!(sys_RT,
                get_forecasts(Deterministic, sys_RT, Dates.DateTime("2020-01-01T00:00:00")),
                Dates.Minute(5),
                12)

InfrastructureSystems.to_json(sys_DA, joinpath(datadir(),"sys_DA.json"))
InfrastructureSystems.to_json(sys_DA, joinpath(datadir(),"sys_RT.json"))

reloaded_sys_da = System(joinpath(datadir(),"sys_DA.json"))
reloaded_sys_rt = System(joinpath(datadir(),"sys_RT.json"))

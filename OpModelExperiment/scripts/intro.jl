import DrWatson
import PowerSystems
import Dates
import InfrastructureSystems

const PSY = PowerSystems
const IS = InfrastructureSystems

########################## Get the data for the model #########################
include(joinpath(DrWatson.srcdir(),"data_handle.jl"))
sha = "367916992a15d5fccf6ce23220c4abae1c27de3d"
base_dir = DrWatson.datadir()

RTS_ROOT = obtain_raw_data(base_dir, sha)
RTS_DIR = joinpath(RTS_ROOT,"RTS_Data/SourceData/")

rts_data = PSY.PowerSystemTableData(RTS_DIR,
    100.0,joinpath(RTS_ROOT,"RTS_Data/FormattedData/SIIP/user_descriptors.yaml"))

sys_DA = PSY.System(rts_data; forecast_resolution = Dates.Hour(1))
for name in ["314_SYNC_COND_1", "114_SYNC_COND_1", "214_SYNC_COND_1"]
    PSY.remove_component!(sys_DA, PSY.get_component(PSY.ThermalStandard, sys_DA, name))
end
sys_RT = PSY.System(rts_data; forecast_resolution = Dates.Minute(5))
for name in ["314_SYNC_COND_1", "114_SYNC_COND_1", "214_SYNC_COND_1"]
    PSY.remove_component!(sys_RT, PSY.get_component(PSY.ThermalStandard, sys_RT, name))
end

###################Convert the data to appropiate Time Series sizes#########################
# Makes Forecasts with 48 hour lookahead and 24 Hour interval
PSY.split_forecasts!(sys_DA,
                PSY.get_forecasts(PSY.Deterministic, sys_DA, Dates.DateTime("2020-01-01T00:00:00")),
                Dates.Hour(24),
                24)

# Makes Forecasts with 1 hour lookahead and 5 minute interval

PSY.split_forecasts!(sys_RT,
                PSY.get_forecasts(PSY.Deterministic, sys_RT, Dates.DateTime("2020-01-01T00:00:00")),
                Dates.Hour(1),
                12)

#PSY.to_json(sys_DA, joinpath(DrWatson.datadir(),"sys_DA.json"))
#PSY.to_json(sys_RT, joinpath(DrWatson.datadir(),"sys_RT.json"))

#eloaded_sys_da = PSY.System(joinpath(DrWatson.datadir(),"sys_DA.json"))
#reloaded_sys_rt = PSY.System(joinpath(DrWatson.datadir(),"sys_RT.json"))

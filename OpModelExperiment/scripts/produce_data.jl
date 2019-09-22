include(joinpath(DrWatson.srcdir(),"data_handle.jl"))
sha = "367916992a15d5fccf6ce23220c4abae1c27de3d"
base_dir = DrWatson.datadir()

RTS_ROOT = obtain_raw_data(base_dir, sha)
TimeSeries_DIR = joinpath(RTS_ROOT,"RTS_Data/timeseries_data_files")


#Attach Time Series data to Unit Commitment
reserves1 = CSV.read(joinpath(TimeSeries_DIR,"/Reserves/DAY_AHEAD_regional_Spin_Up_R1.csv"))
reserves2 = CSV.read(joinpath(TimeSeries_DIR,"/Reserves/DAY_AHEAD_regional_Spin_Up_R2.csv"))
reserves3 = CSV.read(joinpath(TimeSeries_DIR,"/Reserves/DAY_AHEAD_regional_Spin_Up_R3.csv"))
total_reserves = 0.01*(reserves1[!,:Spin_Up_R1] + reserves2[!,:Spin_Up_R2] + reserves3[!,:Spin_Up_R3]);
Time_stamps = DateTime.(reserves1[!,:Year],reserves1[!,:Month], reserves1[!,:Day], (reserves1[!,:Period] .- 1))
reserves_time_array = TimeSeries.TimeArray(Time_stamps, total_reserves, [:Spinning]);

add_forecast!(uc_system, reserves_time_array, reserve5, "Spinning", 1.0)

wind = CSV.read(joinpath(TimeSeries_DIR,"/WIND/DAY_AHEAD_wind.csv"))
wind[!,Symbol("309_WIND_1")] = wind[!,Symbol("309_WIND_1")]./maximum(wind[!,Symbol("309_WIND_1")])
wind[!,Symbol("317_WIND_1")] = wind[!,Symbol("317_WIND_1")]./maximum(wind[!,Symbol("317_WIND_1")])
wind[!,Symbol("303_WIND_1")] = wind[!,Symbol("303_WIND_1")]./maximum(wind[!,Symbol("303_WIND_1")])
wind[!,Symbol("122_WIND_1")] = wind[!,Symbol("122_WIND_1")]./maximum(wind[!,Symbol("122_WIND_1")])
Time_stamps = DateTime.(wind[!,:Year],wind[!,:Month], wind[!,:Day], wind[!,:Period] .- 1)

wind_forecast1 = Deterministic(renewable_generators5[1],"Deterministic",TimeSeries.TimeArray(Time_stamps, wind[!,Symbol("309_WIND_1")]));
wind_forecast2 = Deterministic(renewable_generators5[2],"Deterministic",TimeSeries.TimeArray(Time_stamps, wind[!,Symbol("317_WIND_1")]));
wind_forecast3 = Deterministic(renewable_generators5[3],"Deterministic",TimeSeries.TimeArray(Time_stamps, wind[!,Symbol("122_WIND_1")]));
wind_forecasts = [wind_forecast1, wind_forecast2, wind_forecast3]
add_forecasts!(uc_system, wind_forecasts)

load = CSV.read(joinpath(TimeSeries_DIR,"/Load/DAY_AHEAD_regional_Load.csv"));
load[!,Symbol("1")] = load[!,Symbol("1")]./maximum(load[!,Symbol("1")])
load[!,Symbol("2")] = load[!,Symbol("2")]./maximum(load[!,Symbol("2")])
load[!,Symbol("3")] = load[!,Symbol("3")]./maximum(load[!,Symbol("3")])
Time_stamps = DateTime.(load[!,:Year],load[!,:Month], load[!,:Day], load[!,:Period].- 1)

load_forecast1 = Deterministic(loads5[1],"Deterministic",TimeSeries.TimeArray(Time_stamps, load[!,Symbol("1")]));
load_forecast2 = Deterministic(loads5[2],"Deterministic",TimeSeries.TimeArray(Time_stamps, load[!,Symbol("2")]));
load_forecast3 = Deterministic(loads5[3],"Deterministic",TimeSeries.TimeArray(Time_stamps, load[!,Symbol("3")]));
load_forecast_interruptible = Deterministic(il, "Deterministic",TimeSeries.TimeArray(Time_stamps, load[!,Symbol("3")]));
load_forecasts = [load_forecast1, load_forecast2, load_forecast3, load_forecast_interruptible]
add_forecasts!(uc_system, load_forecasts)

split_forecasts!(uc_system,
                get_forecasts(Deterministic, uc_system, Dates.DateTime("2020-01-01T00:00:00")),
                Dates.Hour(24),
                48)

to_json(uc_system, "data/uc_system.json")


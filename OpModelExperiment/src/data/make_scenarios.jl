function make_scenarios(system::PowerSystems.System, scenario_quantity::Int64, variance::Float64)
    scenario_forecasts = Vector{PowerSystems.ScenarioBased}()
    for data_first_step in PowerSystems.get_forecast_initial_times(system)
        for f in PowerSystems.get_component_forecasts(PowerSystems.RenewableDispatch, system, data_first_step)
            ts = TimeSeries.timestamp(PowerSystems.get_timeseries(f))
            scenarios = Matrix{Float64}(undef, length(ts), scenario_quantity)
            for (ix, v) in enumerate(TimeSeries.values(PowerSystems.get_timeseries(f)))
                x = Random.rand(Distributions.Truncated(Distributions.Normal(v, variance*v), -Inf, 1.0), scenario_quantity)
                scenarios[ix, :] = x'
            end
            scenario_forecast = PowerSystems.ScenarioBased(PowerSystems.get_component(f), "PowerScenarios", TimeSeries.TimeArray(ts, scenarios))
            push!(scenario_forecasts, scenario_forecast)
        end
    end
    return scenario_forecasts
end

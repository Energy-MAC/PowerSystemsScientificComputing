function experiment(treatment::String, Days::UnitRange{Int64}, optimizer)

    uc_simulation_start = first(Days)
    ed_simulation_steps = 24

    raw_ouput_folder = prepare_workspace!("test", joinpath(DrWatson.datadir(), "exp_raw"))
    results_path = joinpath(raw_ouput_folder,remove_char("$(round(Dates.now(),Dates.Minute))", ":"))

    if treatment == "UC"
        ic = make_initial_conditions_from_data(uc_system);
        for e in 1:1
            hour = first(Days)*ed_simulation_steps
            for day in Days
                println(day)
                uc_m = uc_model(uc_system, optimizer, ic, day)
                uc_results_folder = joinpath(results_path, "UC-Day-$(day)")
                mkpath(uc_results_folder)
                solve_JuMPmodel!(uc_m, uc_results_folder)
                for run_case in 1:ed_simulation_steps
                    hour = hour + 1
                    ed_m = ed_model(ed_system, optimizer, hour)
                    ed_results_folder = joinpath(results_path, "ED-Day-$(day)-hour-$(run_case)")
                    mkpath(ed_results_folder)
                    update_commitment_status!(ed_m, uc_m, run_case)
                    solve_JuMPmodel!(ed_m, ed_results_folder)
                    update_initial_conditions!(ic, uc_m, ed_m, run_case)
                end
            end
        end
        return
    end

    if treatment == "SUC"
        ic = make_initial_conditions_from_data(uc_system)
        for e in 1:1
            hour = first(Days)*ed_simulation_steps
            for day in Days
                println(day)
                suc_m = suc_model(suc_system, optimizer, ic, day)
                suc_results_folder = joinpath(results_path, "SUC-Day-$(day)")
                mkpath(suc_results_folder)
                solve_JuMPmodel!(suc_m, suc_results_folder)
                for run in 1:ed_simulation_steps
                    hour = hour + 1
                    ed_m = ed_model(ed_system, optimizer, hour)
                    ed_results_folder = joinpath(results_path, "ED-Day-$(day)-hour-$(run)")
                    mkpath(ed_results_folder)
                    update_commitment_status!(ed_m, suc_m, run)
                    solve_JuMPmodel!(ed_m, ed_results_folder)
                    update_initial_conditions!(ic, suc_m, ed_m, run)
                end
            end
        end

    return
    end

    @warn("$(treatment) not available")

    return

end

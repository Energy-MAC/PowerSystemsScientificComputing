import DrWatson
import PowerSystems
import Dates
import JuMP
import Cbc
import Feather
import DataFrames
import Gurobi
import MathOptInterface
import JSON

const MOI = MathOptInterface
const MOIU = MathOptInterface.Utilities
const PSY = PowerSystems
optimizer = JuMP.with_optimizer(Gurobi.Optimizer, OutputFlag=0)

############################ Load Processed System Data ####################################
uc_system = PSY.System(joinpath(DrWatson.datadir(), "uc_system.json"))
ed_system = PSY.System(joinpath(DrWatson.datadir(), "ed_system.json"))
suc_system = PSY.System(joinpath(DrWatson.datadir(), "suc_system.json"))

include(joinpath(DrWatson.srcdir(), "experiment_utilities.jl"))
################################# Load Function ###########################################
include(joinpath(DrWatson.srcdir(), "computation/SUC_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/ED_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/UC_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/utility_functions.jl"))

include(joinpath(DrWatson.srcdir(), "results/get_results.jl"))
include(joinpath(DrWatson.srcdir(), "results/export_results.jl"))

raw_ouput_folder = prepare_workspace!("test", joinpath(DrWatson.datadir(), "exp_raw"))
results_path = joinpath(raw_ouput_folder,remove_char("$(round(Dates.now(),Dates.Minute))", ":"))

uc_simulation_steps = 30
ed_simulation_steps = 24

ic = make_initial_conditions_from_data(uc_system);
for e in 1:1
    hour = 0
    for day in 1:uc_simulation_steps
        println(day)
        uc_m = uc_model(uc_system, optimizer, ic, day)
        uc_results_folder = joinpath(results_path, "UC-Day-$(day)")
        mkpath(uc_results_folder)
        solve_JuMPmodel!(uc_m, uc_results_folder)
        @show JuMP.value.(uc_m[:ug])
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

ic = make_initial_conditions_from_data(uc_system)
for e in 1:1
    hour = 0
    for day in 1:uc_simulation_steps
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

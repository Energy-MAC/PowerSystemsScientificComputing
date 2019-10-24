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
optimizer = JuMP.with_optimizer(Gurobi.Optimizer, OutputFlag=1)

############################ Load Processed System Data ####################################
uc_system = PSY.System(joinpath(DrWatson.datadir(), "uc_system.json"))
ed_system = PSY.System(joinpath(DrWatson.datadir(), "ed_system.json"))
suc_system = PSY.System(joinpath(DrWatson.datadir(), "suc_system.json"))

include(joinpath(DrWatson.srcdir(), "experiment_utilities.jl"))
################################# Load Functions ###########################################
include(joinpath(DrWatson.srcdir(), "computation/SUC_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/ED_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/UC_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/utility_functions.jl"))
include(joinpath(DrWatson.srcdir(), "computation/trial.jl"))

################################# Results Functions ########################################
include(joinpath(DrWatson.srcdir(), "results/get_results.jl"))
include(joinpath(DrWatson.srcdir(), "results/export_results.jl"))
include(joinpath(DrWatson.srcdir(), "results/collect_results.jl"))
include(joinpath(DrWatson.srcdir(), "results/metrics.jl"))

raw_ouput_folder = prepare_workspace!(joinpath(DrWatson.datadir(), "exp_raw"))
results_date = remove_char("$(round(Dates.now(),Dates.Minute))", ":")
results_path = joinpath(raw_ouput_folder,results_date)

for ix in 1:10
    trial(ix, "UC", range(1+(ix-1)*30, length = 30), optimizer, results_path)
end

for ix in 1:10
    trial(ix, "SUC", range(1+(ix-1)*30, length = 30), optimizer, results_path)
end

fuel_cost_suc = Vector()
load_shedding_suc = Vector()
curtailment_suc = Vector()
computation_times = Vector()
for ix in 1:10
    push!(fuel_cost_suc, total_fuel_cost(results_date, ix, range(1+(ix-1)*30, length = 30), ed_system))
    push!(load_shedding_suc, total_load_not_supplied(results_date, ix,range(1+(ix-1)*30, length = 30), ed_system))
    push!(curtailment_suc, total_curtailment(results_date, ix, range(1+(ix-1)*30, length = 30), ed_system))
    push!(computation_times, total_computing_time(results_date, ix, range(1+(ix-1)*30, length = 30), "SUC"))
end

fuel_cost_uc = Vector()
load_shedding_uc = Vector()
curtailment_uc = Vector()
computation_times = Vector()
for ix in 1:10
    push!(fuel_cost_uc, total_fuel_cost(results_date, ix, range(1+(ix-1)*30, length = 30), ed_system))
    push!(load_shedding_uc, total_load_not_supplied(results_date, ix,range(1+(ix-1)*30, length = 30), ed_system))
    push!(curtailment_uc, total_curtailment(results_date, ix, range(1+(ix-1)*30, length = 30), ed_system))
    push!(computation_times, total_computing_time(results_date, ix, range(1+(ix-1)*30, length = 30), "UC"))
end

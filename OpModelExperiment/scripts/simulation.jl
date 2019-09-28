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
################################# Load Functions ###########################################
include(joinpath(DrWatson.srcdir(), "computation/SUC_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/ED_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/UC_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/utility_functions.jl"))
include(joinpath(DrWatson.srcdir(), "computation/experiment.jl"))

################################# Results Functions ########################################
include(joinpath(DrWatson.srcdir(), "results/get_results.jl"))
include(joinpath(DrWatson.srcdir(), "results/export_results.jl"))

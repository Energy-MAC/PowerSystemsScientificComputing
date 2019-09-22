import DrWatson
import PowerSystems
import Dates
import JuMP
import Gurobi
import GLPK
import Feather
import DataFrames

const PSY = PowerSystems
Gurobi_optimizer = JuMP.with_optimizer(Gurobi.Optimizer)

############################ Load Processed System Data ####################################
uc_system = PSY.System(joinpath(DrWatson.datadir(), "uc_system.json"))
ed_system = PSY.System(joinpath(DrWatson.datadir(), "ed_system.json"))
suc_system = PSY.System(joinpath(DrWatson.datadir(), "suc_system.json"))


################################# Load Function ###########################################
include(joinpath(DrWatson.srcdir(), "computation/SUC_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/ED_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/UC_model.jl"))
include(joinpath(DrWatson.srcdir(), "computation/utility_functions.jl"))

raw_ouput_folder = prepare_workspace!("test", joinpath(DrWatson.datadir(), "exp_raw"))

uc_m = uc_model(uc_system, Gurobi_optimizer)
JuMP.optimize!(uc_m)

ed_m = ed_model(ed_system, Gurobi_optimizer)

update_commitment_status!(ed_m, uc_m, 1)

JuMP.optimize!(ed_m)

suc_m = suc_model(suc_system, Gurobi_optimizer)

JuMP.optimize!(suc_m)
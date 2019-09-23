import DrWatson
import PowerSystems
import Dates
import JuMP
import Cbc
import Feather
import DataFrames
import Gurobi

const PSY = PowerSystems
optimizer = JuMP.with_optimizer(Gurobi.Optimizer, OutputFlag=0)

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



uc_simulation_steps = 2
ed_simulation_steps = 5

include(joinpath(DrWatson.srcdir(), "computation/utility_functions.jl"))
ic = make_initial_conditions_from_data(uc_system);
for day in 1:uc_simulation_steps
    println(day)
    uc_m = uc_model(uc_system, optimizer, ic, day)
    JuMP.optimize!(uc_m)
    @show JuMP.value.(uc_m[:ug])
    for hour in 1:ed_simulation_steps
        println(hour)
        ed_m = ed_model(ed_system, optimizer, hour)
        update_commitment_status!(ed_m, uc_m, hour)
        JuMP.optimize!(ed_m)
        update_initial_conditions!(ic, uc_m, ed_m, hour)
    end
end


suc_m = suc_model(suc_system, optimizer, ic)

JuMP.optimize!(suc_m)

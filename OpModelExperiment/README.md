## SUC experiment

This repository contains the example on how to develop a computational experiment for an
Stochastic Unit Commitment (SUC) formulation. It is not intended to make any claims about SUC.

The folder structure follows the definitions in the paper (The diagram is borrowed from `DrWatson.jl`)

```
│OpModelExperiment
├── data
│   ├── exp_pro         <- Data from processing experiments.
│   └── exp_raw         <- Raw experimental data.
│   └── raw_input_data <- Raw experimental data used as an input. Here the are the downloaded files
│
├── plots               <- Self-explanatory.
├── experimental_notebooks <- Jupyter notebooks used for development.
│
├── scripts             <- The scripts use the `src` folder for their base code.
│   └── simulation.jl   <- Simple file to run the simulation loops.
│   └── produce_data.jl <- This script can be used to re-generate the system experimental data
│
├── src                 <- Source code for use in this project.
│   └── computation     <- Files that contain functions related to computation of the simulations.
│   └── data            <- This folder contains the files for the data management.
│   └── results         <- This folder contains the function to collect results and make results.
│
├── Manifest.toml    <- Contains full list of exact package versions used currently.
└── Project.toml     <- Main project file, allows activation and installation.
```

In order to run the experiment open the Julia project to laod the environment

```
/PowerSystemsScientificComputing/OpModelExperiment julia --project
```

Once in Julia, you can check the the environment has been properly loaded

```Julia
julia>
(OpModelExperiment) pkg> instantiate
(OpModelExperiment) pkg> st
Project OpModelExperiment v0.0.0
    Status `~/Dropbox/Code/PowerSystemsScientificComputing/OpModelExperiment/Project.toml`
  [31c24e10] Distributions v0.21.3
  [634d3b9d] DrWatson v1.4.4
  [becb17da] Feather v0.5.3
  [2e9cd046] Gurobi v0.7.2
  [682c06a0] JSON v0.21.0
  [4076af6c] JuMP v0.20.0
  [b8f27783] MathOptInterface v0.9.5
  [bcd98974] PowerSystems v0.4.2 ⚲
  [9a3f8284] Random
```

# Description
This repository provides the computational experiment to accompany the paper: Lee, Jonathan T., Anderson, Sean, Vergara, Claudio, and Callaway, Duncan. "Non-Intrusive Load Management Under Forecast Uncertainty in Energy Constrained Microgrids." *Electric Power Systems Research*, (Under Review). It also serves as an example for structuring power systems computational experiments as described in: Lara, Jose D., Lee, Jonathan T., Callaway, Duncan, and Hodge, Bri-Mathias. "Computational Experiment Design for Operations Model Simulations." *Electric Power Systems Research*, (Under Review).

# License
This code is made available under the BSD license. We request that any publications that use this code cite either of the papers above (if used to inform research on load management in particular, please cite the first paper, but if used as a reference for experimental design, please cite the second).

# Instructions
The code requires having MATLAB 2018A or higher and CVX version 2.1 installed with a Gurobi license (see http://cvxr.com/cvx/doc/gurobi.html), and is meant to be run from within a MATLAB session.

At the start of a session, load the relevant directories to the MATLAB path by running

`init.m`

See example scripts in the directory `scripts`. The file `runExperiments.m` runs the experiments referenced in the paper, but takes several hours or more. `runExperimentsSample.m` runs smaller example cases that takes minutes. `generateFigures.m` and `generateTables.m` creates the figures and tables used in the paper, respectively.

## Organization

The foler `experiments` holds the class definitions of each experiment. `computation` holds the models of controllers, forecasts, microgrid, the simulation, and general utility functions. `scripts` contains example scripts. `data` contains input data and is the location that output data are written to. Within `data`, the subfolder `common` contains input data common to all experiments. Experiment specific data (both inputs and outputs) are located within the `experiments\inputs` and `experiments\outputs` subfolders and organized by name that corresponds to the experiment definition; i.e. input data pertaining to the `experiments\ControllerPerformanceExperiment.m` experiment are found in `data\experiments\inputs\controllerPerformance`. Within this, specific cases of that experimental setup with different data can be specified as subfolders.

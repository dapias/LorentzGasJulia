include("./input_parameters.jl")
include("./main.jl")
include("./visualization.jl")


using HardDisksSimulation
using Visual

#In this file the main functions of the project are called, i.e. *simulation* from main.jl and *visualizate* from visualization.jl.
#Additionally the parameters from input_parameters.jl are called.

simulacion = simulation(tinicial, tmax, N, Lx1, Lx2, Ly1, Ly2, vmin, vmax);
@time visualize(simulacion, N, Lx1, Lx2, Ly1, Ly2)

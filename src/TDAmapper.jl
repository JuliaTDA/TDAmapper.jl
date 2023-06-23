"""
# TDAmapper.jl

Mapper-like algorithms from Topological Data Analysis.

See https://vituri.github.io/TDAmapper.jl/ for documentation.
"""
module TDAmapper

using BenchmarkTools; using Distances; using ProgressMeter;
using DataFrames;

import Base.Threads.@threads

include("types.jl");
include("sampling.jl");
include("neighborhoods.jl");
include("filter.jl");
include("covering.jl");
include("clustering.jl");
include("mapper.jl");
# include("plots.jl");
include("utils.jl");

export unique_sort,
    epsilon_net, 
    PointCloud,
    excentricity,
    uniform,
    mapper

end # module
"""
# TDAmapper.jl

Mapper-like algorithms from Topological Data Analysis.

See https://vituri.github.io/TDAmapper.jl/ for documentation.
"""
module TDAmapper

# using BenchmarkTools; 
using Distances; using ProgressMeter;
using DataFrames; using NearestNeighbors;

using Graphs

import Base.Threads.@threads

# mapper
include("types.jl");

include("neighborhoods.jl");
include("filter.jl");
include("covering.jl");
include("clustering.jl");
include("pullbacks.jl");
include("graph.jl");
include("mapper.jl");
# include("plots.jl");
include("utils.jl");

# ball mapper
include("sampling.jl");

# example sets
include("example data.jl");
using .Datasets

# types
export PointCloud,
    CoveringIds,
    Mapper

# functions
export unique_sort,
    epsilon_net,     
    excentricity,
    uniform,
    pre_image_id,
    split_pre_image,
    adj_matrix_from_pb,
    mapper,        
    transpose_matrix

end # module
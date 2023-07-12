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
export PointCloud,
    CoveringIds,
    Mapper

include("neighborhoods.jl");
include("filter.jl");

include("covering.jl");
export uniform, spaced

include("clustering.jl");
export cluster_dbscan

include("pullbacks.jl");
include("graph.jl");

export Graph
include("mapper.jl");
export mapper

# include("plots.jl");
include("utils.jl");

# ball mapper
include("sampling.jl");

# example sets
include("example data.jl");
using .Datasets

using Colors; using ColorSchemes;
using CairoMakie; using GraphMakie; import NetworkLayout
include("plots.jl")
export rescale, colorscale, mapper_plot

# functions
export unique_sort,
    epsilon_net,     
    excentricity,
    uniform,
    pre_image_id,
    split_pre_image,
    adj_matrix_from_pb,
    transpose_matrix

end # module
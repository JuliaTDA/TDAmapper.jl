"""
# TDAmapper.jl

Mapper-like algorithms from Topological Data Analysis.

See https://juliatda.github.io/TDAmapper.jl/ for documentation.
"""
module TDAmapper

# using BenchmarkTools; 
using Distances; using ProgressMeter;
using DataFrames; using NearestNeighbors;
using Graphs
using Pipe: @pipe
using StatsBase
export mean;

import Base.Threads.@threads

# mapper
include("types.jl");
export PointCloud,
    CoveringIds,
    Mapper,
    BallMapper,
    AbstractMapper,
    Interval,
    in,
    intersect;

# not needed anymore; using NearestNeighbors.jl
# include("neighborhoods.jl");

include("filter.jl");
export excentricity;

include("covering.jl");
export uniform, spaced;

include("clustering.jl");
export cluster_dbscan

include("pullbacks.jl");
include("graph.jl");

export Graph;
include("mapper.jl");
export mapper,
    adj_matrix_from_covering;

include("utils.jl");
export unique_sort,
    transpose_matrix;

include("sampling.jl");
export epsilon_net;

using Colors; using ColorSchemes;
using GLMakie; import NetworkLayout
include("plots.jl");
export rescale, 
    colorscale, 
    mapper_plot, 
    calculate_node_colors;

include("ball_mapper.jl");
export ball_mapper;

end # module
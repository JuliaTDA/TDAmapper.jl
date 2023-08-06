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
    SubsetIndex,
    Covering,
    CoveredPointCloud,
    AbstractMapper,
    AbstractMapperGraph,
    MapperGraph,
    Mapper,
    BallMapper,
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
export cluster_dbscan,
    split_covering;

include("pullbacks.jl");
export pre_image_covering;

using MultivariateStats;
include("graph.jl");
export mds_layout;

include("nerve.jl");
export centroid;

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
    node_colors;

include("ball_mapper.jl");
export ball_mapper;

end # module
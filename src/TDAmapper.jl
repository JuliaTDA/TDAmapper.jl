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

export mean,
    @pipe,
    DataFrame,
    groupby;

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

include("filter.jl");
export excentricity;

include("covering.jl");
export uniform, spaced;

include("clustering.jl");
export cluster_dbscan,
    split_covering;

include("pullbacks.jl");
export pre_image_covering;

using MultivariateStats, ManifoldLearning;
include("layouts.jl");
export layout_generic,
    layout_mds,
    layout_hlle,
    layout_isomap,
    layout_lem,
    layout_lle,
    layout_ltsa,
    layout_tsne,
    layout_diffmap;

include("nerve.jl");
export centroid;

export Graph;
include("mapper.jl");
export mapper;

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
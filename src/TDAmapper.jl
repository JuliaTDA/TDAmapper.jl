"""
# TDAmapper.jl

Mapper-like algorithms from Topological Data Analysis.

See https://juliatda.github.io/TDAmapper.jl/ for documentation.
"""
module TDAmapper

# using BenchmarkTools; 
using Distances; using ProgressMeter;
using Reexport;
@reexport using MetricSpaces;
using NearestNeighbors
using StatsBase

using Revise, TestItems, TestItemRunner
using Graphs
export Graph;

import Base.Threads.@threads

# mapper
include("types.jl");
export AbstractMapper,
    Mapper,
    BallMapper,
    GeneralMapper;

include("IntervalCovering/IntervalCoverings.jl");
export IntervalCoverings;

include("ImageCoverings/ImageCoverings.jl");
export ImageCoverings;

include("ClusterCoverings/ClusterCoverings.jl");
export ClusterCoverings;

include("utils.jl");
export unique_sort;

include("mapper.jl");
export mapper;

include("ball_mapper.jl");
export 
    ball_mapper,
    ball_mapper_generic;

end # module
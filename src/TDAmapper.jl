"""
# TDAmapper.jl

Mapper-like algorithms from Topological Data Analysis.

See https://juliatda.github.io/TDAmapper.jl/ for documentation.
"""
module TDAmapper

# using BenchmarkTools; 
using ProgressMeter
using Reexport
@reexport using MetricSpaces

using Revise, TestItems, TestItemRunner
using Graphs
export Graph

import Base.Threads.@threads

# mapper
include("types.jl")
export AbstractMapper,
    Mapper,
    BallMapper,
    GeneralMapper

include("cover.jl")
export AbstractCover,
    make_cover,
    empty_cover

include("IntervalCovers/IntervalCovers.jl")
export IntervalCover

include("ImageCovers/ImageCovers.jl")
export ImageCovers

include("DomainCovers/DomainCovers.jl")
export DomainCovers

include("Refiners/Refiners.jl")
export Refiners

include("Nerves/Nerves.jl")
export Nerves

include("generic_mapper.jl");
export general_mapper

include("mapper.jl")
export mapper

include("ball_mapper.jl")
export ball_mapper,
    ball_mapper_generic

# include("generic_mapper.jl")
# export generic_mapper

end # module
"""
# TDAmapper.jl

Mapper-like algorithms from Topological Data Analysis.

See https://juliatda.github.io/TDAmapper.jl/ for documentation.
"""
module TDAmapper

using ProgressMeter
using Reexport
@reexport using MetricSpaces

using TestItems
using Graphs
export Graph

import Base.Threads.@threads

# Type alias for coverings
const Covering = Vector{Vector{Int}}
export Covering

# Interval type for interval covers
struct Interval
    a::Real
    b::Real
end
Base.in(x::Real, I::Interval) = I.a <= x <= I.b
export Interval

# Mapper types
include("types.jl")
export AbstractMapper, Mapper

include("cover.jl")
export AbstractCover, make_cover

include("IntervalCovers/IntervalCovers.jl")
export IntervalCovers

include("ImageCovers/ImageCovers.jl")
export ImageCovers

include("DomainCovers/DomainCovers.jl")
export DomainCovers

include("Refiners/Refiners.jl")
export Refiners

include("Nerves/Nerves.jl")
export Nerves

include("mapper.jl")
export mapper

include("classical_mapper.jl")
export classical_mapper

include("ball_mapper.jl")
export ball_mapper

end # module
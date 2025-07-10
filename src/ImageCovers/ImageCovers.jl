module ImageCovers

using ..TDAmapper
using ..TDAmapper.IntervalCovers: AbstractIntervalCover
using TestItems

"""
    AbstractImageCover

Abstract type for image coverings that create pullback covers of metric spaces.

# Interface Requirements
Subtypes must implement:
- `make_cover(ic::AbstractImageCover) -> Vector{Vector{Int}}`: 
  Returns a covering as a vector of index vectors

# Optional Interface
- `(ic::AbstractImageCover)(X::MetricSpace, f_X::Vector{<:Real})`: 
  Callable interface for direct application
"""
abstract type AbstractImageCover <: AbstractCover end
export AbstractImageCover

include("r1.jl")
export R1Covering

end # module
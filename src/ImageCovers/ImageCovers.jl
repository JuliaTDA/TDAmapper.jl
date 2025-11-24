"""
    ImageCovers

A module containing image covering implementations for mapper algorithms.

Image covers work by taking the image of a filter function f: X → ℝ and creating 
a covering of this image space (typically intervals on the real line). The covering 
of the original space X is then obtained by taking the pullback of this image covering.

# Exports
- [`AbstractImageCover`](@ref): Abstract base type for image covering strategies
- [`R1Cover`](@ref): Covering implementation for real-valued filter functions
- [`make_cover`](@ref): Interface method for generating coverings

# Interface
All image cover implementations must provide:
- `make_cover(ic::AbstractImageCover) -> Vector{Vector{Int}}`

Optionally, they may also implement:
- `(ic::AbstractImageCover)(X::MetricSpace, f_X::Vector{<:Real})`: Callable interface
"""
module ImageCovers

using ..TDAmapper
using ..TDAmapper.IntervalCovers: AbstractIntervalCover
using TestItems

"""
    AbstractImageCover <: AbstractCover

Abstract type for image coverings that create pullback covers of metric spaces.

Image covers work by:
1. Taking a filter function f: X → ℝ
2. Creating a covering of the image f(X) ⊆ ℝ (usually with intervals)
3. Taking the pullback f⁻¹(covering) to get a covering of X

# Interface Requirements
Subtypes must implement:
- `make_cover(ic::AbstractImageCover) -> Vector{Vector{Int}}`: 
  Returns a covering as a vector of index vectors

# Optional Interface
- `(ic::AbstractImageCover)(X::MetricSpace, f_X::Vector{<:Real})`: 
  Callable interface for direct application

# Examples
The typical workflow is:
1. Define a filter function on your metric space
2. Create an interval covering of the filter's range  
3. Use an ImageCover to pull back this covering to the original space

# See Also
- [`R1Cover`](@ref): Concrete implementation for real-valued filters
- [`AbstractCover`](@ref): Parent abstract type
"""
abstract type AbstractImageCover <: AbstractCover end
export AbstractImageCover

include("r1.jl")
export R1Cover, make_cover

end # module
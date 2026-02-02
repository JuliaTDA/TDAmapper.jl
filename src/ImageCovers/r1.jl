using ..TDAmapper: Interval

"""
    R1Cover{T<:Real, I<:Interval} <: AbstractImageCover

A covering implementation for real-valued filter functions on metric spaces.

# Type Parameters
- `T<:Real`: The numeric type for filter values
- `I<:Interval`: The concrete interval type

# Fields
- `f_X::Vector{T}`: The filter values computed on the metric space
- `U::Vector{I}`: The interval covering of the filter's range

# Description
`R1Cover` implements image coverings for filter functions f: X → ℝ by:
1. Taking the filter values f_X = [f(x₁), f(x₂), ..., f(xₙ)]
2. Using an interval covering U of the range of f
3. Computing the pullback covering by finding points whose filter values fall in each interval

This is the standard approach used in classical mapper algorithms.

# Constructors
- `R1Cover(f_X, U)`: Direct construction with filter values and intervals
- `R1Cover(f_X, int_cov::AbstractIntervalCover)`: Construction using an interval covering strategy

# Examples
```julia
using TDAmapper
using TDAmapper.ImageCovers, TDAmapper.IntervalCovers

# Method 1: Direct construction
f_X = [1.0, 2.5, 3.2, 1.8]
U = [Interval(1.0, 2.0), Interval(1.5, 3.0), Interval(2.5, 3.5)]
cover = R1Cover(f_X=f_X, U=U)

# Method 2: Using an interval covering
uniform_cover = Uniform(expansion=0.2)
cover2 = R1Cover(f_X, uniform_cover)

# Generate the actual covering
covering = make_cover(cover)  # Returns vector of index vectors
```

# See Also
- [`make_cover`](@ref): Generate the covering from this strategy
- [`AbstractIntervalCover`](@ref): Interface for interval covering strategies
- [`Uniform`](@ref): A common interval covering implementation
"""
@kwdef struct R1Cover{T<:Real, I<:Interval} <: AbstractImageCover
    f_X::Vector{T}
    U::Vector{I}
end

"""
    R1Cover(f_X, int_cov::AbstractIntervalCover) -> R1Cover

Construct an R1Cover using an interval covering strategy.

# Arguments
- `f_X`: Vector of filter values
- `int_cov::AbstractIntervalCover`: Strategy for covering the filter's range

# Returns
- `R1Cover`: Configured with the filter values and computed intervals

# Description
This constructor applies the interval covering strategy to the range of the filter
values to automatically generate the interval covering.
"""
function R1Cover(f_X, int_cov::AbstractIntervalCover)
    R1Cover(f_X=f_X, U=int_cov(f_X))
end

"""
    TDAmapper.make_cover(img_cov::R1Cover) -> Vector{Vector{Int}}

Generate the pullback covering from an R1Cover.

# Arguments
- `img_cov::R1Cover`: The image cover configuration

# Returns
- `Vector{Vector{Int}}`: A covering where each element is a vector of indices 
  of points whose filter values fall within the corresponding interval

# Description
For each interval in `img_cov.U`, this function finds all indices i such that 
`img_cov.f_X[i] ∈ interval`, creating the pullback covering f⁻¹(U).

# Examples
```julia
f_X = [1.0, 2.0, 3.0]
U = [Interval(0.5, 1.5), Interval(1.5, 2.5), Interval(2.5, 3.5)]
img_cov = R1Cover(f_X=f_X, U=U)
covering = make_cover(img_cov)  # Returns [[1], [2], [3]]
```
"""
# extend method from main module
function TDAmapper.make_cover(img_cov::R1Cover)
    n = length(img_cov.f_X)
    m = length(img_cov.U)

    # Early return for edge cases
    m == 0 && return Vector{Int}[]
    n == 0 && return [Int[] for _ in 1:m]

    # Single-pass algorithm: iterate over points once, assign to matching intervals
    cover = [Int[] for _ in 1:m]

    @inbounds for (i, val) in enumerate(img_cov.f_X)
        for (j, interval) in enumerate(img_cov.U)
            if val ∈ interval
                push!(cover[j], i)
            end
        end
    end

    return cover
end

@testitem "R1Cover" begin
    using TDAmapper
    using TDAmapper.ImageCovers

    f_X = float([1, 2, 3])
    U = [Interval(0.0, 0.5), Interval(0.5, 1.5), Interval(1.5, 4.0)]
    img_cov = R1Cover(f_X=f_X, U=U)
    cover = make_cover(img_cov)

    @test cover == [[], [1], [2, 3]]


    f_X = Float64[]
    U = [Interval(0.0, 1.0), Interval(1.0, 2.0)]
    img_cov = R1Cover(f_X=f_X, U=U)
    cover = make_cover(img_cov)    
   
    @test cover == [[], []]


    f_X = float([1, 2, 3])
    U = Interval[]
    img_cov = R1Cover(f_X=f_X, U=U)
    cover = make_cover(img_cov)
   
    @test cover == []
end
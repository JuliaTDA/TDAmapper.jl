"""
    Uniform <: AbstractIntervalCover

A uniform interval covering that divides the range of a filter vector into equally-spaced intervals
with configurable overlap.

# Fields
- `length::Integer`: The number of intervals to create (must be > 1)
- `expansion::Real`: The expansion factor for overlap between intervals (must be ≥ 0)
  - 0.0 means intervals just touch at endpoints
  - 1.0 means each interval is doubled in size, creating significant overlap

# Example
```julia
covering = Uniform(length=10, expansion=0.25)
intervals = covering([1.0, 2.0, 3.0, 4.0, 5.0])
```
"""
@kwdef struct Uniform <: AbstractIntervalCover
    length::Integer=10
    expansion::Real=0.25
end

"""
    (U::Uniform)(x::Vector{<:Real})

Apply the uniform covering to a filter vector `x`.

This is a callable struct implementation that allows a `Uniform` instance to be used
as a function. It delegates to the `uniform` function with the struct's parameters.

# Arguments
- `x::Vector{<:Real}`: The filter vector to be covered

# Returns
- `Vector{Interval}`: A vector of intervals covering the range of `x`

# Example
```julia
covering = Uniform(length=5, expansion=0.1)
intervals = covering([1.0, 2.0, 3.0, 4.0, 5.0])
```
"""
function (U::Uniform)(x::Vector{<:Real})
    uniform(x, length=U.length, expansion=U.expansion)
end

"""
    uniform(x::Vector{<:Real}; length::Integer = 10, expansion::Real = 0.25)

Create a uniform covering of filter vector `x`.

This function creates a uniform interval covering by:
1. Finding the extrema (min and max) of the input vector `x`
2. Dividing this range into `length` equally-spaced points
3. Creating intervals centered at these points with overlap controlled by `expansion`

# Arguments
- `x::Vector{<:Real}`: The filter vector to be covered

# Keyword Arguments
- `length::Integer = 10`: The number of intervals to create (must be > 1)
- `expansion::Real = 0.25`: The expansion factor for interval overlap (must be ≥ 0)
  - 0.0 creates intervals that just touch at their endpoints
  - Higher values create more overlap between adjacent intervals

# Returns
- `Vector{Interval}`: A vector of `Interval` objects covering the range of `x`

# Throws
- `AssertionError`: If `length ≤ 1` or `expansion < 0`

# Example
```julia
x = [1.0, 2.0, 3.0, 4.0, 5.0]
intervals = uniform(x, length=3, expansion=0.5)
# Creates 3 overlapping intervals covering the range [1.0, 5.0]
```

# Algorithm Details
The algorithm works as follows:
1. Compute the range: `min_x` to `max_x`
2. Create `length` equally-spaced division points
3. Calculate interval radius as: `(step_size / 2) * (1 + expansion)`
4. Create intervals centered at each division point with the calculated radius
"""
function uniform(
    x::Vector{<:Real}
    ; length::Integer=10, expansion::Real=0.25
)
    @assert length > 1 "`length` must be greater than 1"
    @assert expansion >= 0 "`expansion` must be non-negative"

    division = range(extrema(x)..., length=length)
    radius = ((division[2] - division[1]) / 2) * (1 + expansion)

    return [Interval(i - radius, i + radius) for i ∈ division]
end

@testitem "uniform" begin
    using TDAmapper
    using TDAmapper.IntervalCovers
    x = [0, 1]
    @test_throws AssertionError uniform(x, length=1)
    @test_throws AssertionError uniform(x, length=1, expansion=-1)

    U = Uniform(length=2, expansion=0)
    cover = uniform(x, length=2, expansion=0)
    @test U(x) == cover
    @test cover == [Interval(-0.5, 0.5), Interval(0.5, 1.5)]

    cover = uniform(x, length=2, expansion=1)
    @test cover == [Interval(-1.0, 1.0), Interval(0.0, 2.0)]

    for expansion ∈ 0:0.1:1
        local cover = uniform(x, length=2, expansion=expansion)
        @test abs(cover[1].b - cover[2].a) ≈ expansion
    end

    cover = uniform([1, 10], length=10, expansion=1)
    @test length(cover) == 10
    @test cover[1] == Interval(0.0, 2.0)
end

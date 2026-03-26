"""
    DyadicCover <: AbstractIntervalCover

A multi-resolution interval covering via recursive binary subdivision. Refines intervals
only where sufficient data points exist.

# Fields
- `max_depth::Int`: Maximum recursion depth (must be ≥ 1)
- `min_points::Int`: Minimum number of points to allow further subdivision (must be ≥ 1)
- `expansion::Float64`: The expansion factor for overlap between intervals (must be ≥ 0)

# Example
```julia
covering = DyadicCover(max_depth=5, min_points=10, expansion=0.25)
intervals = covering(randn(1000))
```
"""
@kwdef struct DyadicCover <: AbstractIntervalCover
    max_depth::Int = 5
    min_points::Int = 10
    expansion::Float64 = 0.25
end

"""
    (D::DyadicCover)(x::Vector{<:Real})

Apply the dyadic covering to a filter vector `x`.

# Arguments
- `x::Vector{<:Real}`: The filter vector to be covered

# Returns
- `Vector{Interval}`: A vector of intervals covering the range of `x`
"""
function (D::DyadicCover)(x::Vector{<:Real})
    dyadic_cover(x, max_depth=D.max_depth, min_points=D.min_points, expansion=D.expansion)
end

"""
    dyadic_cover(x::Vector{<:Real}; max_depth::Integer=5, min_points::Integer=10, expansion::Real=0.25)

Create a multi-resolution covering of filter vector `x` via recursive binary subdivision.

The algorithm starts with the full range and recursively bisects intervals that contain
at least `min_points` data points, up to `max_depth` levels.

# Arguments
- `x::Vector{<:Real}`: The filter vector to be covered

# Keyword Arguments
- `max_depth::Integer = 5`: Maximum recursion depth (must be ≥ 1)
- `min_points::Integer = 10`: Minimum points required to subdivide (must be ≥ 1)
- `expansion::Real = 0.25`: The expansion factor for interval overlap (must be ≥ 0)

# Returns
- `Vector{Interval}`: A vector of `Interval` objects covering the range of `x`

# Throws
- `ArgumentError`: If `max_depth < 1`, `min_points < 1`, or `expansion < 0`
"""
function dyadic_cover(
    x::Vector{<:Real}
    ; max_depth::Integer=5, min_points::Integer=10, expansion::Real=0.25
)
    max_depth >= 1 || throw(ArgumentError("`max_depth` must be ≥ 1"))
    min_points >= 1 || throw(ArgumentError("`min_points` must be ≥ 1"))
    expansion >= 0 || throw(ArgumentError("`expansion` must be non-negative"))

    min_x, max_x = extrema(x)
    leaves = Tuple{Float64,Float64}[]
    _bisect!(leaves, x, min_x, max_x, 1, max_depth, min_points)

    return map(leaves) do (a, b)
        half_width = (b - a) / 2
        center = (a + b) / 2
        Interval(center - half_width * (1 + expansion), center + half_width * (1 + expansion))
    end
end

function _bisect!(leaves, x, a, b, depth, max_depth, min_points)
    n = count(xi -> a <= xi <= b, x)

    if n < min_points || depth > max_depth
        push!(leaves, (a, b))
        return
    end

    mid = (a + b) / 2
    _bisect!(leaves, x, a, mid, depth + 1, max_depth, min_points)
    _bisect!(leaves, x, mid, b, depth + 1, max_depth, min_points)
end

@testitem "dyadic_cover" begin
    using TDAmapper
    using TDAmapper.IntervalCovers

    x = randn(1000)
    @test_throws ArgumentError dyadic_cover(x, max_depth=0)
    @test_throws ArgumentError dyadic_cover(x, min_points=0)
    @test_throws ArgumentError dyadic_cover(x, expansion=-1)

    D = DyadicCover(max_depth=3, min_points=10, expansion=0.25)
    @test D(x) == dyadic_cover(x, max_depth=3, min_points=10, expansion=0.25)

    cover = dyadic_cover(x, max_depth=3, min_points=10, expansion=0.1)

    # all points should be covered
    for xi in x
        @test any(xi ∈ iv for iv in cover)
    end

    # respects max_depth: at depth d we get at most 2^d leaves
    @test length(cover) <= 2^3

    # more intervals in dense regions:
    # bimodal data — dense cluster near 0, sparse near 10
    bimodal = vcat(randn(900), randn(100) .+ 10)
    cover = dyadic_cover(bimodal, max_depth=5, min_points=20, expansion=0.0)
    # dense region should have more intervals than sparse region
    midpoint = 5.0  # roughly between the two clusters
    n_left = count(iv -> (iv.a + iv.b) / 2 < midpoint, cover)
    n_right = count(iv -> (iv.a + iv.b) / 2 >= midpoint, cover)
    @test n_left > n_right
end

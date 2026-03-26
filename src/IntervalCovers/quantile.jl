"""
    QuantileCover <: AbstractIntervalCover

An interval covering that divides the range of a filter vector into intervals where each
interval contains approximately the same number of data points.

# Fields
- `n_intervals::Int`: The number of intervals to create (must be > 1)
- `expansion::Float64`: The expansion factor for overlap between intervals (must be ≥ 0)

# Example
```julia
covering = QuantileCover(n_intervals=10, expansion=0.25)
intervals = covering([1.0, 2.0, 3.0, 4.0, 5.0])
```
"""
@kwdef struct QuantileCover <: AbstractIntervalCover
    n_intervals::Int = 10
    expansion::Float64 = 0.25
end

"""
    (Q::QuantileCover)(x::Vector{<:Real})

Apply the quantile covering to a filter vector `x`.

# Arguments
- `x::Vector{<:Real}`: The filter vector to be covered

# Returns
- `Vector{Interval}`: A vector of intervals covering the range of `x`
"""
function (Q::QuantileCover)(x::Vector{<:Real})
    quantile_cover(x, n_intervals=Q.n_intervals, expansion=Q.expansion)
end

"""
    quantile_cover(x::Vector{<:Real}; n_intervals::Integer=10, expansion::Real=0.25)

Create a quantile-based covering of filter vector `x`.

Each interval contains approximately the same number of data points.

# Arguments
- `x::Vector{<:Real}`: The filter vector to be covered

# Keyword Arguments
- `n_intervals::Integer = 10`: The number of intervals to create (must be > 1)
- `expansion::Real = 0.25`: The expansion factor for interval overlap (must be ≥ 0)

# Returns
- `Vector{Interval}`: A vector of `Interval` objects covering the range of `x`

# Throws
- `ArgumentError`: If `n_intervals ≤ 1` or `expansion < 0`
"""
function quantile_cover(
    x::Vector{<:Real}
    ; n_intervals::Integer=10, expansion::Real=0.25
)
    n_intervals > 1 || throw(ArgumentError("`n_intervals` must be greater than 1"))
    expansion >= 0 || throw(ArgumentError("`expansion` must be non-negative"))

    sorted = sort(x)
    n = length(sorted)
    probs = range(0, 1, length=n_intervals + 1)
    breakpoints = map(probs) do p
        idx = clamp(1 + p * (n - 1), 1, n)
        lo = floor(Int, idx)
        hi = ceil(Int, idx)
        frac = idx - lo
        sorted[lo] * (1 - frac) + sorted[hi] * frac
    end

    return map(1:n_intervals) do i
        a, b = breakpoints[i], breakpoints[i + 1]
        half_width = (b - a) / 2
        center = (a + b) / 2
        Interval(center - half_width * (1 + expansion), center + half_width * (1 + expansion))
    end
end

@testitem "quantile_cover" begin
    using TDAmapper
    using TDAmapper.IntervalCovers

    x = [0.0, 1.0]
    @test_throws ArgumentError quantile_cover(x, n_intervals=1)
    @test_throws ArgumentError quantile_cover(x, n_intervals=2, expansion=-1)

    Q = QuantileCover(n_intervals=2, expansion=0.25)
    @test Q(x) == quantile_cover(x, n_intervals=2, expansion=0.25)

    # all points should be covered
    x = randn(1000)
    cover = quantile_cover(x, n_intervals=5, expansion=0.1)
    @test length(cover) == 5
    for xi in x
        @test any(xi ∈ iv for iv in cover)
    end

    # each interval should have roughly equal point count
    counts = [count(xi ∈ iv for xi in x) for iv in cover]
    expected = length(x) / 5
    for c in counts
        @test c >= expected * 0.5  # at least half the expected count
    end
end

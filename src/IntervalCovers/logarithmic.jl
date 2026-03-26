"""
    LogarithmicCover{T<:Real} <: AbstractIntervalCover

An interval covering with logarithmically-spaced intervals. Useful when filter values
span multiple orders of magnitude.

# Type Parameters
- `T<:Real`: The numeric type for the expansion parameter

# Fields
- `n_intervals::Int`: The number of intervals to create (must be > 1)
- `expansion::T`: The expansion factor for overlap between intervals (must be ≥ 0)

# Example
```julia
covering = LogarithmicCover(n_intervals=10, expansion=0.25)
intervals = covering([1.0, 10.0, 100.0, 1000.0])
```
"""
@kwdef struct LogarithmicCover{T<:Real} <: AbstractIntervalCover
    n_intervals::Int = 10
    expansion::T = 0.25
end

"""
    (L::LogarithmicCover)(x::Vector{<:Real})

Apply the logarithmic covering to a filter vector `x`.

# Arguments
- `x::Vector{<:Real}`: The filter vector to be covered

# Returns
- `Vector{Interval}`: A vector of intervals covering the range of `x`
"""
function (L::LogarithmicCover)(x::Vector{<:Real})
    logarithmic_cover(x, n_intervals=L.n_intervals, expansion=L.expansion)
end

"""
    logarithmic_cover(x::Vector{<:Real}; n_intervals::Integer=10, expansion::Real=0.25)

Create a logarithmically-spaced covering of filter vector `x`.

The algorithm shifts the data so the minimum maps to 1, divides the log-range uniformly,
then exponentiates back to the original scale.

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
function logarithmic_cover(
    x::Vector{<:Real}
    ; n_intervals::Integer=10, expansion::Real=0.25
)
    n_intervals > 1 || throw(ArgumentError("`n_intervals` must be greater than 1"))
    expansion >= 0 || throw(ArgumentError("`expansion` must be non-negative"))

    min_x, max_x = extrema(x)
    shift = 1 - min_x  # shift so minimum maps to 1

    log_min = log(1.0)  # = 0
    log_max = log(max_x + shift)

    log_points = range(log_min, log_max, length=n_intervals + 1)
    points = exp.(log_points) .- shift

    return map(1:n_intervals) do i
        a, b = points[i], points[i + 1]
        half_width = (b - a) / 2
        center = (a + b) / 2
        Interval(center - half_width * (1 + expansion), center + half_width * (1 + expansion))
    end
end

@testitem "logarithmic_cover" begin
    using TDAmapper
    using TDAmapper.IntervalCovers

    x = [1.0, 1000.0]
    @test_throws ArgumentError logarithmic_cover(x, n_intervals=1)
    @test_throws ArgumentError logarithmic_cover(x, n_intervals=2, expansion=-1)

    L = LogarithmicCover(n_intervals=3, expansion=0.25)
    @test L(x) == logarithmic_cover(x, n_intervals=3, expansion=0.25)

    cover = logarithmic_cover(x, n_intervals=4, expansion=0.1)
    @test length(cover) == 4

    # intervals should widen going right
    widths = [iv.b - iv.a for iv in cover]
    for i in 1:length(widths)-1
        @test widths[i] < widths[i + 1]
    end

    # all points should be covered
    x_test = [1.0, 10.0, 100.0, 500.0, 1000.0]
    cover = logarithmic_cover(x_test, n_intervals=5, expansion=0.25)
    for xi in x_test
        @test any(xi ∈ iv for iv in cover)
    end
end

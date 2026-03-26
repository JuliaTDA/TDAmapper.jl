"""
    AdaptiveCover <: AbstractIntervalCover

An interval covering that creates narrower intervals in dense regions and wider intervals
in sparse regions, using histogram-based density estimation.

# Fields
- `n_intervals::Int`: The number of intervals to create (must be > 1)
- `expansion::Float64`: The expansion factor for overlap between intervals (must be ≥ 0)
- `n_bins::Int`: The number of histogram bins for density estimation (must be ≥ n_intervals)

# Example
```julia
covering = AdaptiveCover(n_intervals=10, expansion=0.25, n_bins=100)
intervals = covering(randn(1000))
```
"""
@kwdef struct AdaptiveCover <: AbstractIntervalCover
    n_intervals::Int = 10
    expansion::Float64 = 0.25
    n_bins::Int = 100
end

"""
    (A::AdaptiveCover)(x::Vector{<:Real})

Apply the adaptive covering to a filter vector `x`.

# Arguments
- `x::Vector{<:Real}`: The filter vector to be covered

# Returns
- `Vector{Interval}`: A vector of intervals covering the range of `x`
"""
function (A::AdaptiveCover)(x::Vector{<:Real})
    adaptive_cover(x, n_intervals=A.n_intervals, expansion=A.expansion, n_bins=A.n_bins)
end

"""
    adaptive_cover(x::Vector{<:Real}; n_intervals::Integer=10, expansion::Real=0.25, n_bins::Integer=100)

Create a density-adaptive covering of filter vector `x`.

Dense regions get narrower intervals (more resolution), sparse regions get wider intervals.
Uses a histogram-based density estimate with inverse-CDF breakpoint placement.

# Arguments
- `x::Vector{<:Real}`: The filter vector to be covered

# Keyword Arguments
- `n_intervals::Integer = 10`: The number of intervals to create (must be > 1)
- `expansion::Real = 0.25`: The expansion factor for interval overlap (must be ≥ 0)
- `n_bins::Integer = 100`: The number of histogram bins (must be ≥ n_intervals)

# Returns
- `Vector{Interval}`: A vector of `Interval` objects covering the range of `x`

# Throws
- `ArgumentError`: If `n_intervals ≤ 1`, `expansion < 0`, or `n_bins < n_intervals`
"""
function adaptive_cover(
    x::Vector{<:Real}
    ; n_intervals::Integer=10, expansion::Real=0.25, n_bins::Integer=100
)
    n_intervals > 1 || throw(ArgumentError("`n_intervals` must be greater than 1"))
    expansion >= 0 || throw(ArgumentError("`expansion` must be non-negative"))
    n_bins >= n_intervals || throw(ArgumentError("`n_bins` must be ≥ `n_intervals`"))

    min_x, max_x = extrema(x)
    bin_edges = range(min_x, max_x, length=n_bins + 1)
    bin_width = bin_edges[2] - bin_edges[1]

    # build histogram counts
    counts = zeros(Int, n_bins)
    for xi in x
        idx = clamp(floor(Int, (xi - min_x) / bin_width) + 1, 1, n_bins)
        counts[idx] += 1
    end

    # cumulative density
    cdf = cumsum(counts) ./ sum(counts)

    # find breakpoints via inverse CDF
    breakpoints = Vector{Float64}(undef, n_intervals + 1)
    breakpoints[1] = min_x
    breakpoints[end] = max_x

    for i in 1:n_intervals-1
        target = i / n_intervals
        # find first bin where CDF >= target
        bin_idx = searchsortedfirst(cdf, target)
        bin_idx = clamp(bin_idx, 1, n_bins)
        breakpoints[i + 1] = bin_edges[bin_idx]
    end

    # ensure breakpoints are sorted and unique (clamp duplicates)
    for i in 2:length(breakpoints)
        if breakpoints[i] <= breakpoints[i - 1]
            breakpoints[i] = breakpoints[i - 1] + eps(breakpoints[i - 1])
        end
    end

    return map(1:n_intervals) do i
        a, b = breakpoints[i], breakpoints[i + 1]
        half_width = (b - a) / 2
        center = (a + b) / 2
        Interval(center - half_width * (1 + expansion), center + half_width * (1 + expansion))
    end
end

@testitem "adaptive_cover" begin
    using TDAmapper
    using TDAmapper.IntervalCovers

    x = randn(1000)
    @test_throws ArgumentError adaptive_cover(x, n_intervals=1)
    @test_throws ArgumentError adaptive_cover(x, n_intervals=2, expansion=-1)
    @test_throws ArgumentError adaptive_cover(x, n_intervals=10, n_bins=5)

    A = AdaptiveCover(n_intervals=5, expansion=0.25, n_bins=50)
    @test A(x) == adaptive_cover(x, n_intervals=5, expansion=0.25, n_bins=50)

    cover = adaptive_cover(x, n_intervals=5, expansion=0.1, n_bins=50)
    @test length(cover) == 5

    # all points should be covered
    for xi in x
        @test any(xi ∈ iv for iv in cover)
    end

    # dense regions should get narrower intervals:
    # create bimodal data with a dense cluster near 0 and sparse tail
    bimodal = vcat(randn(900), randn(100) .+ 10)
    cover = adaptive_cover(bimodal, n_intervals=4, expansion=0.0, n_bins=100)
    widths = [iv.b - iv.a for iv in cover]
    # the first intervals (dense region) should be narrower than the last (sparse region)
    @test widths[1] < widths[end]
end

"""
    ManualCover{T<:Real} <: AbstractIntervalCover

An interval covering where the user provides explicit intervals, either as breakpoints
or as a vector of `Interval` objects.

# Fields
- `intervals::Vector{Interval{T}}`: The pre-specified intervals

# Constructors
- `ManualCover(intervals::Vector{<:Interval})`: Direct from intervals
- `ManualCover(breakpoints::Vector{<:Real}; expansion=0.0)`: From sorted breakpoints

# Examples
```julia
# From breakpoints
cover = ManualCover([0.0, 1.0, 2.0, 3.0], expansion=0.1)

# From explicit intervals
cover = ManualCover([Interval(0.0, 1.5), Interval(1.0, 3.0)])
```
"""
struct ManualCover{T<:Real} <: AbstractIntervalCover
    intervals::Vector{Interval{T}}
end

function ManualCover(breakpoints::Vector{T}; expansion::Real=0.0) where {T<:Real}
    ManualCover(manual_cover(breakpoints, expansion=expansion))
end

"""
    (M::ManualCover)(x::Vector{<:Real})

Return the pre-specified intervals. The input `x` is ignored since intervals are fixed.

# Returns
- `Vector{Interval}`: The stored intervals
"""
function (M::ManualCover)(::Vector{<:Real})
    M.intervals
end

"""
    manual_cover(breakpoints::Vector{<:Real}; expansion::Real=0.0)

Create an interval covering from sorted breakpoints.

Adjacent breakpoints define intervals: `[b₁, b₂], [b₂, b₃], ...`
Each interval is then expanded by the `expansion` factor.

# Arguments
- `breakpoints::Vector{<:Real}`: Sorted values defining interval boundaries

# Keyword Arguments
- `expansion::Real = 0.0`: The expansion factor for interval overlap (must be ≥ 0)

# Returns
- `Vector{Interval}`: A vector of `Interval` objects

# Throws
- `ArgumentError`: If `length(breakpoints) < 2`, breakpoints not sorted, or `expansion < 0`
"""
function manual_cover(
    breakpoints::Vector{<:Real}
    ; expansion::Real=0.0
)
    length(breakpoints) >= 2 || throw(ArgumentError("`breakpoints` must have at least 2 elements"))
    issorted(breakpoints) || throw(ArgumentError("`breakpoints` must be sorted"))
    expansion >= 0 || throw(ArgumentError("`expansion` must be non-negative"))

    return map(1:length(breakpoints)-1) do i
        a, b = breakpoints[i], breakpoints[i + 1]
        half_width = (b - a) / 2
        center = (a + b) / 2
        Interval(center - half_width * (1 + expansion), center + half_width * (1 + expansion))
    end
end

@testitem "manual_cover" begin
    using TDAmapper
    using TDAmapper.IntervalCovers

    # validation
    @test_throws ArgumentError manual_cover([1.0])
    @test_throws ArgumentError manual_cover([2.0, 1.0])
    @test_throws ArgumentError manual_cover([0.0, 1.0], expansion=-1)

    # from breakpoints, no expansion
    cover = manual_cover([0.0, 1.0, 2.0], expansion=0.0)
    @test length(cover) == 2
    @test cover[1] == Interval(0.0, 1.0)
    @test cover[2] == Interval(1.0, 2.0)

    # from breakpoints with expansion
    cover = manual_cover([0.0, 1.0, 2.0], expansion=0.5)
    @test cover[1] == Interval(-0.25, 1.25)

    # struct from breakpoints
    M = ManualCover([0.0, 1.0, 2.0], expansion=0.0)
    @test M([99.0]) == [Interval(0.0, 1.0), Interval(1.0, 2.0)]

    # struct from explicit intervals
    intervals = [Interval(0.0, 1.5), Interval(1.0, 3.0)]
    M2 = ManualCover(intervals)
    @test M2([99.0]) == intervals
end

@kwdef struct Uniform <: AbstractIntervalCovering
    length::Integer
    expansion::Real
end

function (U::Uniform)(x::Vector{<:Real})
    uniform(x, length=U.length, expansion=U.expansion)
end

"""
    uniform(x::Vector{<:Real}; length::Integer = 15, overlap::Real = 100)

Create an uniform covering of filter vector `x`. First we order `x` and then split it in `length` elements, then we create the overlaps.
"""
function uniform(
    x::Vector{<:Real}
    ; length::Integer=10, expansion::Real=0.25
)
    @assert length > 1 "`length` must be greater than 1!"
    @assert expansion >= 0 "`expansion` must be non-negative"

    division = range(extrema(x)..., length=length)
    radius = ((division[2] - division[1]) / 2) * (1 + expansion)

    return [Interval(i - radius, i + radius) for i ∈ division]
end

@testitem "uniform" begin
    using TDAmapper
    x = [0, 1]
    @test_throws AssertionError uniform(x, length=1)

    U = Uniform(length=2, expansion=0)
    cover = uniform(x, length=2, expansion=0)
    @test U(x) == cover
    @test cover == [Interval(-0.5, 0.5), Interval(0.5, 1.5)]

    cover = uniform(x, length=2, expansion=1)
    @test cover == [Interval(-1.0, 1.0), Interval(0.0, 2.0)]

    for expansion ∈ [0:0.1:1;]
        local cover = uniform(x, length=2, expansion=expansion)
        @test abs(cover[1].b - cover[2].a) ≈ expansion
    end

    cover = uniform([1, 10], length=10, expansion=1)
    @test length(cover) == 10
    @test cover[1] == Interval(0.0, 2.0)
end

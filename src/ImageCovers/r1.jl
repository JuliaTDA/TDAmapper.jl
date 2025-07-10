@kwdef struct R1Covering <: AbstractImageCover    
    f_X::Vector{<:Real}
    U::Vector{Interval}
end

function R1Covering(f_X, int_cov::AbstractIntervalCover)
    R1Covering(f_X=f_X, U=int_cov(f_X))
end

# pullback
function make_cover(img_cov::R1Covering)
    [findall(x -> x ∈ c, img_cov.f_X) for c ∈ img_cov.U]
end

@testitem "R1Covering" begin
    using TDAmapper
    using TDAmapper: ImageCovers

    f_X = float([1, 2, 3])
    U = [Interval(0.0, 0.5), Interval(0.5, 1.5), Interval(1.5, 4.0)]
    img_cov = R1Covering(f_X=f_X, U=U)
    cover = make_cover(img_cov)

    @test cover == [[], [1], [2, 3]]
end

@testitem "R1Covering: empty f_X" begin
    f_X = Float64[]
    U = [Interval(0.0, 1.0), Interval(1.0, 2.0)]
    img_cov = R1Covering(f_X=f_X, U=U)
    cover = make_cover(img_cov)    
    @test cover == [[], []]
end

@testitem "R1Covering: empty interval_covering" begin
    f_X = float([1, 2, 3])
    U = Interval[]
    img_cov = R1Covering(f_X=f_X, U=U)
    cover = make_cover(img_cov)
    @test cover == []
end
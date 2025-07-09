module ImageCoverings

using ..TDAmapper
using ..TDAmapper.IntervalCoverings: AbstractIntervalCovering
using TestItems

abstract type AbstractImageCovering end
export AbstractImageCovering

@kwdef struct ImageCovering <: AbstractImageCovering
    X::MetricSpace
    f_X::Vector{<:Real}
    U::Vector{Interval}
end
# generalize here: use T instead of Real; the same for Interval.
# works for R^n?

function ImageCovering(X, f_X, int_cov::AbstractIntervalCovering)
    ImageCovering(X=X, f_X=f_X, U=int_cov(f_X))
end

metric_space(img_cov::ImageCovering) = img_cov.X #??

# pullback
function covering(img_cov::ImageCovering)
    [findall(x -> x ∈ c, img_cov.f_X) for c ∈ img_cov.U]
end

@testitem "covering" begin
    using TDAmapper
    f_X = float([1, 2, 3])
    U = [Interval(0.0, 0.5), Interval(0.5, 1.5), Interval(1.5, 4.0)]
    img_cov = ImageCovering(X=X, f_X=f_X, U=U)
    cov = covering(img_cov)

    @test cov == [[], [1], [2, 3]]
end

@testitem "covering: empty f_X" begin
    f_X = Float64[]
    interval_covering = [Interval(0.0, 1.0), Interval(1.0, 2.0)]
    pb = pullback(f_X, interval_covering)
    @test pb == [[], []]
end

@testitem "covering: empty interval_covering" begin
    f_X = float([1, 2, 3])
    interval_covering = Interval[]
    pb = pullback(f_X, interval_covering)
    @test pb == []
end
end # module
"""
    pre_image_id

For each point x of `fv`, find the indexes i of interval_covering
such that x ∈ interval_covering[i]
"""
function pullback(
    fv::Vector{<:Real}, interval_covering::Vector{<:Interval}
)
    [findall(x -> x ∈ c, fv) for c ∈ interval_covering]
end

@testitem "pullback" begin
    fv = float([1, 2, 3])
    interval_covering = [Interval(0.0, 0.5), Interval(0.5, 1.5), Interval(1.5, 4.0)]
    pb = pullback(fv, interval_covering)
    
    @test pb  == [[], [1], [2, 3]]
end

@testitem "pullback: empty fv" begin
    fv = Float64[]
    interval_covering = [Interval(0.0, 1.0), Interval(1.0, 2.0)]
    pb = pullback(fv, interval_covering)
    @test pb == [[], []]
end

@testitem "pullback: empty interval_covering" begin
    fv = float([1, 2, 3])
    interval_covering = Interval[]
    pb = pullback(fv, interval_covering)
    @test pb == []
end
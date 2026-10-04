using TDAmapper
using TDAmapper.ImageCovers, TDAmapper.IntervalCovers, TDAmapper.Refiners, TDAmapper.Nerves
using Aqua
using Test
using TestItemRunner
using MetricSpaces.Datasets: sphere
using Graphs: nv, ne

# Neural weak dependencies enlarge Aqua's isolated precompile wrapper. Keep the
# shutdown test enabled, allowing extra shutdown time on Julia 1.12.
Aqua.test_all(TDAmapper;persistent_tasks=(tmax=120,))

@run_package_tests

include("test_neural_filters.jl")

@testset "Integration tests" begin
    @testset "End-to-end classical mapper on sphere" begin
        X = sphere(500, dim=2)
        fv = first.(X)
        ic = R1Cover(fv, Uniform(length=5, expansion=0.3))
        M = classical_mapper(X, ic, DBscan(radius=0.2))
        @test M isa Mapper
        @test length(M.C) > 0
        @test all(c -> length(c) > 0, M.C)
        @test nv(M.g) == length(M.C)
        @test ne(M.g) >= 0
    end

    @testset "End-to-end ball mapper" begin
        X = sphere(200)
        L = farthest_points_sample_ids(X, 20)
        M = ball_mapper(X, L, 0.5)
        @test M isa Mapper
        @test nv(M.g) == 20
    end

    @testset "Interval from MetricSpaces works in TDAmapper" begin
        i = Interval(1.0, 3.0)
        @test 2.0 ∈ i
        @test !(4.0 ∈ i)
        @test_throws ArgumentError Interval(3.0, 1.0)
    end
end

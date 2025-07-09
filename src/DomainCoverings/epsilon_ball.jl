@kwdef struct EpsilonBallCovering
    L::Covering
    ϵ::Real
end

function (EB::EpsilonBallCovering)(X::MetricSpace)
    epsilon_ball_covering(X; L=EB.L, ϵ=EB.ϵ)
end

function epsilon_ball_covering(X::MetricSpace; L::Covering, ϵ=1)
    @assert length(L) > 0 "L must have at least one element!"
    @assert L ⊆ eachindex(X) "L must be a subset of indeces of X!"

    X_matrix = as_matrix(X)
    covering = empty_covering(length(L))

    for (i, l) ∈ enumerate(L)
        covering[i] = inrange(BallTree(X_matrix), X[l], ϵ)
    end

    return covering
end

@testitem "epsilon_ball_covering" begin
    using TDAmapper

    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1, 2, 3]
    ϵ = 0.9
    
    @test epsilon_ball_covering(X, L=L, ϵ=ϵ) == [[1], [2], [3]]
    
    EB = EpsilonBallCovering(L = L, ϵ = ϵ)
    @test epsilon_ball_covering(X, L=L, ϵ=ϵ) == EB(X)

    
    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1, 2, 3]
    ϵ = 1

    @test epsilon_ball_covering(X, L=L, ϵ=ϵ) == [[1, 2], [1, 2, 3], [2, 3]]

    EB = EpsilonBallCovering(L = L, ϵ = ϵ)
    @test epsilon_ball_covering(X, L=L, ϵ=ϵ) == EB(X)

    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1]
    ϵ = 1.5

    @test epsilon_ball_covering(X, L=L, ϵ=ϵ) == [[1, 2]]

    EB = EpsilonBallCovering(L = L, ϵ = ϵ)
    @test epsilon_ball_covering(X, L=L, ϵ=ϵ) == EB(X)

    
    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = Int[]
    @test_throws AssertionError epsilon_ball_covering(X, L=L)

    L = [4]
    @test_throws AssertionError epsilon_ball_covering(X, L=L)

    X = sphere(101)
    L = [1:10:101;]
    ϵ = 0.00000001
    cover = epsilon_ball_covering(X, L=L, ϵ=ϵ)
    @test all(==(1), length.(cover))
end
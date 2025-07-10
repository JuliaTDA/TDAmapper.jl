using Distances
import NearestNeighbors as NN

@kwdef struct EpsilonBall <: AbstractDomainCovering
    L::Covering
    epsilon::Real
    metric::Euclidean()
end

function (EB::EpsilonBall)(X::MetricSpace)
    epsilon_ball(X; L=EB.L, epsilon=EB.epsilon, metric=EB.metric)
end

function epsilon_ball(
    X::MetricSpace;
    L::Covering, epsilon=1, metric=Euclidean
)
    @assert length(L) > 0 "L must have at least one element!"
    @assert L ⊆ eachindex(X) "L must be a subset of indeces of X!"

    X_matrix = as_matrix(X)
    cover = empty_cover(length(L))

    for (i, l) ∈ enumerate(L)
        cover[i] = NN.inrange(NN.BallTree(X_matrix, metric=metric), X[l], epsilon)
    end

    return cover
end

@testitem "epsilon_ball" begin
    using TDAmapper

    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1, 2, 3]
    epsilon = 0.9

    @test epsilon_ball(X, L=L, epsilon=epsilon) == [[1], [2], [3]]

    EB = EpsilonBall(L=L, epsilon=epsilon)
    @test epsilon_ball(X, L=L, epsilon=epsilon) == EB(X)


    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1, 2, 3]
    epsilon = 1

    @test epsilon_ball(X, L=L, epsilon=epsilon) == [[1, 2], [1, 2, 3], [2, 3]]

    EB = EpsilonBall(L=L, epsilon=epsilon)
    @test epsilon_ball(X, L=L, epsilon=epsilon) == EB(X)

    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1]
    epsilon = 1.5

    @test epsilon_ball(X, L=L, epsilon=epsilon) == [[1, 2]]

    EB = EpsilonBall(L=L, epsilon=epsilon)
    @test epsilon_ball(X, L=L, epsilon=epsilon) == EB(X)


    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = Int[]
    @test_throws AssertionError epsilon_ball(X, L=L)

    L = [4]
    @test_throws AssertionError epsilon_ball(X, L=L)

    X = sphere(101)
    L = [1:10:101;]
    epsilon = 0.00000001
    cover = epsilon_ball(X, L=L, epsilon=epsilon)
    @test all(==(1), length.(cover))
end
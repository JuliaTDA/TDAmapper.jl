using Distances
import NearestNeighbors as NN

"""
    EpsilonBall <: AbstractDomainCover

A domain covering strategy using balls of fixed radius around landmark points.

# Fields
- `L::Vector{<:Integer}`: Indices of landmark points in the metric space
- `epsilon::Real`: Radius of the balls around each landmark point  
- `metric`: Distance metric to use (default: `Euclidean()`)

# Description
`EpsilonBall` creates a covering by placing a ball of radius `epsilon` around each 
landmark point specified in `L`. Each ball contains all points within distance 
`epsilon` of the corresponding landmark.

This is the standard covering used in ball mapper algorithms.

# Examples
```julia
using TDAmapper.DomainCovers
using Distances

# Create ball covering with Euclidean distance
cover_strategy = EpsilonBall(L=[1, 3, 5], epsilon=1.5)

# Create ball covering with Manhattan distance  
cover_strategy = EpsilonBall(L=[1, 2], epsilon=2.0, metric=Cityblock())

# Apply to a metric space
X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0]])
covering = cover_strategy(X)
```

# See Also
- [`epsilon_ball`](@ref): Function interface for the same functionality
- [`AbstractDomainCover`](@ref): Parent abstract type
"""
@kwdef struct EpsilonBall <: AbstractDomainCover
    L::Vector{<:Integer}
    epsilon::Real
    metric=Euclidean()
end

"""
    (EB::EpsilonBall)(X::MetricSpace) -> Vector{Vector{Int}}

Apply epsilon ball covering to a metric space.

# Arguments
- `X::MetricSpace`: The metric space to cover

# Returns
- `Vector{Vector{Int}}`: A covering where each element contains the indices of 
  points within `epsilon` distance of the corresponding landmark

# Description
This callable interface allows using `EpsilonBall` instances as functions.
It delegates to the `epsilon_ball` function with the struct's parameters.
"""
function (EB::EpsilonBall)(X::MetricSpace)
    epsilon_ball(X; L=EB.L, epsilon=EB.epsilon, metric=EB.metric)
end

"""
    epsilon_ball(X::MetricSpace; L::Vector{<:Integer}, epsilon::Real=1, metric=Euclidean()) -> Vector{Vector{Int}}

Create an epsilon ball covering of a metric space.

# Arguments
- `X::MetricSpace`: The metric space to cover

# Keyword Arguments  
- `L::Vector{<:Integer}`: Indices of landmark points (must be valid indices into X)
- `epsilon::Real=1`: Radius of the balls around each landmark
- `metric=Euclidean()`: Distance metric to use

# Returns
- `Vector{Vector{Int}}`: A covering where `result[i]` contains all point indices 
  within distance `epsilon` of landmark `X[L[i]]`

# Throws
- `AssertionError`: If `L` is empty or contains invalid indices

# Description
For each landmark point `X[L[i]]`, this function finds all points in `X` that are 
within distance `epsilon` using the specified metric. This creates overlapping 
balls that form the covering.

The function uses efficient nearest neighbor data structures for fast distance queries.

# Examples
```julia
using TDAmapper.DomainCovers

X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0], [1.5, 2.5]])
L = [1, 3]  # Use points 1 and 3 as landmarks
epsilon = 1.0

covering = epsilon_ball(X, L=L, epsilon=epsilon)
# Returns: [[1, 4], [3, 4]] if points 4 is close to both landmarks
```

# See Also
- [`EpsilonBall`](@ref): Struct interface for the same functionality
"""
function epsilon_ball(
    X::MetricSpace;
    L::Vector{<:Integer}, epsilon::Real=1, metric=Euclidean()
)
    @assert length(L) > 0 "L must have at least one element!"
    @assert L ⊆ eachindex(X) "L must be a subset of indeces of X!"

    X_matrix = as_matrix(X)
    cover = empty_cover(length(L))

    for (i, l) ∈ enumerate(L)
        cover[i] = NN.inrange(NN.BallTree(X_matrix, metric), X[l], epsilon)
    end

    return cover
end

@testitem "epsilon_ball" begin
    using TDAmapper
    using TDAmapper.DomainCovers

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
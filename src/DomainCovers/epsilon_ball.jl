using Distances
import NearestNeighbors as NN

"""
    EpsilonBall <: AbstractDomainCover

A domain covering strategy using balls of fixed radius around landmark points.

# Fields
- `X::MetricSpace`: The metric space containing the data points
- `L::Vector{<:Integer}`: Indices of landmark points in the metric space
- `epsilon::Real`: Radius of the balls around each landmark point (default: 1)
- `metric`: Distance metric to use (default: `Euclidean()`)

# Description
`EpsilonBall` creates a covering by placing a ball of radius `epsilon` around each 
landmark point specified in `L`. Each ball contains all points within distance 
`epsilon` of the corresponding landmark. The metric space `X` is stored in the 
struct along with the covering parameters.

This is the standard covering used in ball mapper algorithms.

# Examples
```julia
using TDAmapper.DomainCovers
using Distances

X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0]])

# Create ball covering with Euclidean distance
cover_strategy = EpsilonBall(X=X, L=[1, 3], epsilon=1.5)
covering = cover_strategy()  # Apply the covering

# Create ball covering with Manhattan distance  
cover_strategy = EpsilonBall(X=X, L=[1, 2], epsilon=2.0, metric=Cityblock())
covering = cover_strategy()  # Apply the covering
```

# See Also
- [`epsilon_ball`](@ref): Function interface for the same functionality
- [`AbstractDomainCover`](@ref): Parent abstract type
"""
@kwdef struct EpsilonBall <: AbstractDomainCover
    X::MetricSpace
    L::Vector{<:Integer}
    epsilon::Real = 1
    metric = Euclidean()
end

"""
    (EB::EpsilonBall)() -> Vector{Vector{Int}}

Apply epsilon ball covering to the stored metric space.

# Returns
- `Vector{Vector{Int}}`: A covering where each element contains the indices of 
  points within `epsilon` distance of the corresponding landmark

# Description
This callable interface allows using `EpsilonBall` instances as functions.
It applies the epsilon ball covering to the metric space stored in the struct,
creating a ball of radius `epsilon` around each landmark point.

Uses efficient nearest neighbor search via the `inrange` function from 
NearestNeighbors.jl for optimal performance.

# Examples
```julia
using TDAmapper.DomainCovers

X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0], [4.0, 1.0]])
cover = EpsilonBall(X=X, L=[1, 3], epsilon=1.5)
covering = cover()  # Apply the covering

# Access individual balls
first_ball = covering[1]  # Points near landmark 1
second_ball = covering[2]  # Points near landmark 3
```

# See Also
- [`epsilon_ball`](@ref): Function interface for the same functionality
"""
function (EB::EpsilonBall)()
    @assert length(EB.L) > 0 "L must have at least one element!"
    @assert EB.L ⊆ eachindex(EB.X) "L must be a subset of indeces of X!"

    X_matrix = as_matrix(EB.X)
    cover = empty_cover(length(EB.L))

    for (i, l) ∈ enumerate(EB.L)
        cover[i] = NN.inrange(NN.BallTree(X_matrix, EB.metric), EB.X[l], EB.epsilon)
    end

    return cover
end

TDAmapper.make_cover(EB::EpsilonBall) = EB()

"""
    epsilon_ball(X::MetricSpace, L::Vector{<:Integer}; epsilon::Real=1, metric=Euclidean()) -> Vector{Vector{Int}}

Create an epsilon ball covering of a metric space.

# Arguments
- `X::MetricSpace`: The metric space to cover
- `L::Vector{<:Integer}`: Indices of landmark points around which to place balls
- `epsilon::Real`: Radius of the balls (default: 1)
- `metric`: Distance metric to use (default: `Euclidean()`)

# Returns
- `Vector{Vector{Int}}`: A covering where each element contains the indices of 
  points within `epsilon` distance of the corresponding landmark

# Description
This function creates a covering by placing a ball of radius `epsilon` around each 
landmark point specified in `L`. Each ball contains all points within distance 
`epsilon` of the corresponding landmark.

This is a functional interface equivalent to creating an `EpsilonBall` struct and 
calling it immediately.

# Examples
```julia
using TDAmapper.DomainCovers

X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0], [4.0, 1.0]])
covering = epsilon_ball(X, [1, 3], epsilon=1.5)

# Equivalent to:
# cover = EpsilonBall(X=X, L=[1, 3], epsilon=1.5)
# covering = cover()
```

# See Also
- [`EpsilonBall`](@ref): Struct-based interface for the same functionality
"""
function epsilon_ball(X::MetricSpace, L::Vector{<:Integer}; epsilon::Real=1, metric=Euclidean())
    return EpsilonBall(X=X, L=L, epsilon=epsilon, metric=metric)()
end

@testitem "EpsilonBall" begin
    using TDAmapper
    using TDAmapper.DomainCovers

    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1, 2, 3]
    epsilon = 0.9

    @test EpsilonBall(X=X, L=L, epsilon=epsilon)() == [[1], [2], [3]]


    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1, 2, 3]
    epsilon = 1

    @test EpsilonBall(X=X, L=L, epsilon=epsilon)() == [[1, 2], [1, 2, 3], [2, 3]]


    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1]
    epsilon = 1.5

    @test EpsilonBall(X=X, L=L, epsilon=epsilon)() == [[1, 2]]


    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = Int[]
    @test_throws AssertionError EpsilonBall(X=X, L=L, epsilon=epsilon)()

    L = [4]
    @test_throws AssertionError EpsilonBall(X=X, L=L, epsilon=epsilon)()

    X = sphere(101)
    L = [1:10:101;]
    epsilon = 0.00000001
    cover = EpsilonBall(X=X, L=L, epsilon=epsilon)()
    @test all(==(1), length.(cover))
end

@testitem "epsilon_ball function interface" begin
    using TDAmapper
    using TDAmapper.DomainCovers

    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1, 2, 3]
    epsilon = 0.9

    # Test function interface
    result_func = epsilon_ball(X, L, epsilon=epsilon)
    
    # Test struct interface  
    result_struct = EpsilonBall(X=X, L=L, epsilon=epsilon)()
    
    # Should produce identical results
    @test result_func == result_struct
    @test result_func == [[1], [2], [3]]

    # Test with different parameters
    result2 = epsilon_ball(X, [1], epsilon=1.5)
    @test result2 == [[1, 2]]
end
"""
    ball_mapper(X::MetricSpace, L::Vector{<:Integer}, epsilon=1) -> Mapper

Creates the ball mapper of a metric space `X` subsampled by `L`.

# Arguments
- `X::MetricSpace`: a point cloud.
- `L::Vector{<:Integer}`: a subset of index of `X`, that is:
    L is a subset of [1:size(X)[2]].
- `epsilon`: the radius of the balls around the points
    `X[:, l]` for `l` ∈ `L` (positional argument, default `1`).

# Returns
- `Mapper`: A mapper object containing the metric space, covering, and nerve graph.

# Details
For each index `i` of `L`, we define `c_i` as the ball of 
radius `ϵ` around `X[:, i]`. We then define the cover 
`C = {c_i, i ∈ L}.`

After that, we define the ball mapper as the graph given by
the 1-skeleton of `C`.

# Examples
```julia
using TDAmapper
X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0]])
L = [1, 2, 3]  # Use all points as landmarks
ϵ = 1.5
mapper = ball_mapper(X, L, ϵ)
```

# See Also
- [`mapper`](@ref): The generic mapper pipeline used internally
- [`DomainCovers.EpsilonBall`](@ref): The domain covering strategy backing `ball_mapper`
"""
function ball_mapper(X::MetricSpace, L::Vector{<:Integer}, epsilon=1)
    mapper(
        X,
        TDAmapper.DomainCovers.EpsilonBall(X=X, L=L, epsilon=epsilon),
        TDAmapper.Refiners.Trivial(),
        TDAmapper.Nerves.SimpleNerve()
    )
end

@testitem "ball_mapper" begin
    using TDAmapper
    using MetricSpaces.Datasets: sphere
    using Graphs: nv, ne

    X = [1, 2, 3] .|> float |> EuclideanSpace
    L = [1, 2, 3]
    epsilon = 1.0

    M = ball_mapper(X, L, epsilon)
    g = M.g
    @test nv(g) == 3
    @test nv(g) == 3

    X = sphere(1000);
    L = [1:100;]
    epsilon = 0.1
    
    M = ball_mapper(X, L, epsilon)
    g = M.g
    @test nv(g) == 100
    @test ne(g) >= 200
end
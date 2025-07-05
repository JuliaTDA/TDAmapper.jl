function epsilon_ball_covering(X::MetricSpace, L::Vector{<:Integer}; ϵ=1)

    covering = inrange(BallTree(X), X[:, L], ϵ)

    return covering
end

"""
    ball_mapper_generic(
        X::MetricSpace, L::Vector{<:Integer}, 
        covering_function::Function,
        graph_function::Function
        )

Creates the ball mapper of a metric space `X` subsampled by `L`.

# Arguments

- `X::MetricSpace`: a point cloud.
- `L::Vector{<:Integer}`: a subset of index of `X`, that is:
    L is a subset of [1:size(X)[2]].
- `covering_function::Function`: a function that creates  
    a cover for `X`. Its arguments are `X` and `L`.
- `graph_function::Function`: a function that creates
    a graph. It accepts a `CoveredMetricSpace` object.

# Details

See the "Generalization" page of the online documentation.
"""
function ball_mapper_generic(
    X::MetricSpace, L::Vector{<:Integer},
    covering_function::Function,
    graph_function::Function
)
    covering = covering_function(X, L)
    CX = CoveredMetricSpace(X, covering)
    graph = graph_function(CX)

    mp = BallMapper(
        CX=CX, L=L, graph=graph
    )
end

"""
    ball_mapper(
        X::MetricSpace, L::Vector{<:Integer}; 
        ϵ::Number = 1
        )

Creates the ball mapper of a metric space `X` subsampled by `L`.

# Arguments

- `X::MetricSpace`: a point cloud.
- `L::Vector{<:Integer}`: a subset of index of `X`, that is:
    L is a subset of [1:size(X)[2]].
- `ϵ::Number`: the radius of the balls around the points
    `X[:, l]` for `l` ∈ `L`.

# Details
For each index `i` of `L`, we define `c_i` as the ball of 
radius `ϵ` around `X[:, i]`. We then define the covering 
`C = {c_i, i ∈ L}.`

After that, we define the ball mapper as the graph given by
the 1-skeleton of `C`.
"""
function ball_mapper(X::MetricSpace, L::Vector{<:Integer}; ϵ=1)
    f = (x, l) -> epsilon_ball_covering(x, l, ϵ=ϵ)
    ball_mapper_generic(X, L, f, nerve_1d)
end
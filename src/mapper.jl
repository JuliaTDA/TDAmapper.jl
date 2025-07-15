"""
    mapper(X::MetricSpace, C, R, N) -> GeneralMapper

A generic mapper implementation that combines covering, refinement, and nerve construction.

# Arguments
- `X::MetricSpace`: The input metric space containing the data points
- `C`: A covering strategy (must implement `make_cover`)
- `R`: A refinement strategy (must be callable on metric spaces)
- `N`: A nerve construction strategy (must implement `make_graph`)

# Returns
- `Mapper`: A mapper object containing the metric space, refined covering, and graph

# Description
This function implements a generic mapper algorithm by:
1. Creating an initial covering using `make_cover(C)`
2. Refining the covering using `refine_cover(X, raw_cover, R)`
3. Constructing a graph using `make_graph(X, cover, N)`

This provides a flexible framework for implementing different mapper variants
by combining different covering, refinement, and nerve strategies.

# Examples
```julia
using TDAmapper
using TDAmapper.ImageCovers, TDAmapper.Refiners, TDAmapper.Nerves

X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0]])
f_X = [1.0, 2.0, 1.5]  # Filter values
C = R1Cover(f_X=f_X, U=[Interval(0.5, 1.5), Interval(1.0, 2.5)])
R = Trivial()
N = SimpleNerve()

M = mapper(X, C, R, N)
```

# See Also
- [`classical_mapper`](@ref): Specialized mapper for image covers
- [`ball_mapper`](@ref): Specialized for ball mappers
"""
function mapper(X::MetricSpace, C, R, N)
    raw_cover = make_cover(C)
    cover = refine_cover(X, raw_cover, R)
    g = make_graph(X, cover, N)

    Mapper(X=X, C=cover, g=g)
end

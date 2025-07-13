# # raw_cover = cover_function(X)
# # cover = cluster(raw_cover)
# # g = nerve_function(cover)

"""
    generic_mapper(X::MetricSpace, C, R, N) -> GeneralMapper

A generic mapper implementation that combines covering, refinement, and nerve construction.

# Arguments
- `X::MetricSpace`: The input metric space containing the data points
- `C`: A covering strategy (must implement `make_cover`)
- `R`: A refinement strategy (must be callable on metric spaces)
- `N`: A nerve construction strategy (must implement `make_graph`)

# Returns
- `GeneralMapper`: A mapper object containing the metric space, refined covering, and graph

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

mapper = generic_mapper(X, C, R, N)
```

# See Also
- [`mapper`](@ref): Specialized mapper for image covers
- [`ball_mapper_generic`](@ref): Specialized for ball mappers
"""
function generic_mapper(X::MetricSpace, C, R, N)
    raw_cover = make_cover(C)
    cover = refine_cover(X, raw_cover, R)
    g = make_graph(X, cover, N)

    GeneralMapper(X=X, C=cover, g=g)
end

# function mapper(X::MetricSpace, C::AbstractImageCover, R, N)
    
# end

# function ball_mapper(X::MetricSpace, C::AbstractDomaingCovering, R, N)
    
# end
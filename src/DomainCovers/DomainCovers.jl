"""
    DomainCovers

A module containing domain covering implementations for mapper algorithms.

Domain covers work directly on the metric space X by creating overlapping regions 
(typically balls or neighborhoods) around selected landmark points. This is in 
contrast to image covers which work via a filter function.

# Exports
- [`AbstractDomainCover`](@ref): Abstract base type for domain covering strategies
- [`EpsilonBall`](@ref): Ball covering with fixed radius
- [`epsilon_ball`](@ref): Function interface for epsilon ball covering

# Interface
All domain cover implementations should provide a callable interface:
- `(dc::AbstractDomainCover)(X::MetricSpace) -> Vector{Vector{Int}}`

# Examples
Domain covers are particularly useful for ball mapper algorithms:
```julia
using TDAmapper.DomainCovers
X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0]])
L = [1, 3]  # Landmark indices
cover_strategy = EpsilonBall(L=L, epsilon=1.0)
covering = cover_strategy(X)  # Returns covering as index vectors
```
"""
module DomainCovers

using ..TDAmapper
using TestItems

"""
    AbstractDomainCover <: AbstractCover

Abstract base type for domain covering strategies.

Domain covers create coverings by working directly on the metric space, typically 
by placing overlapping regions (like balls or neighborhoods) around selected points.
This approach is used in ball mapper and related algorithms.

# Interface
Concrete subtypes should implement the callable interface:
- `(dc::AbstractDomainCover)(X::MetricSpace) -> Vector{Vector{Int}}`

# Examples
Domain covers typically involve:
1. Selecting landmark points in the metric space
2. Creating overlapping regions (balls, neighborhoods) around these landmarks  
3. Finding all points that fall within each region

# See Also
- [`EpsilonBall`](@ref): Concrete implementation using balls of fixed radius
- [`AbstractCover`](@ref): Parent abstract type
"""
abstract type AbstractDomainCover <: AbstractCover end
export AbstractDomainCover

include("epsilon_ball.jl")
export EpsilonBall,
    epsilon_ball

end # module
"""
    Refiners

A module containing refinement strategies for mapper algorithms.

Refinement is the clustering step in mapper algorithms where each element of an 
initial covering is further subdivided into clusters. This allows the algorithm 
to capture finer structure within each cover element.

# Exports
- [`AbstractRefiner`](@ref): Abstract base type for refinement strategies
- [`create_outlier_cluster`](@ref): Utility for handling clustering outliers
- [`refine_cover`](@ref): Main refinement function
- [`DBscan`](@ref): DBSCAN clustering refiner
- [`Trivial`](@ref): No-clustering refiner

# Interface
All refiner implementations must provide a callable interface:
- `(r::AbstractRefiner)(X::MetricSpace) -> Vector{Int}`

# Examples
Refiners are used in the mapper pipeline to cluster points within each cover element:
```julia
using TDAmapper.Refiners

X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0]])
dbscan = DBscan(radius=0.5)
clusters = dbscan(X)  # Returns cluster assignments [1, 2, 1] or similar
```
"""
module Refiners
using ..TDAmapper
using TestItems

"""
    AbstractRefiner

Abstract base type for all refinement strategies.

Refiners define how to cluster or subdivide each element of a covering in mapper 
algorithms. They take a metric space (typically a subset corresponding to one 
cover element) and return cluster assignments for the points.

# Interface
All concrete refiner types must implement the callable interface:
- `(r::AbstractRefiner)(X::MetricSpace) -> Vector{Int}`

Where the returned vector contains cluster assignments (positive integers) for 
each point in the metric space.

# Examples
Common refinement strategies include:
- Clustering algorithms (DBSCAN, k-means, hierarchical clustering)
- Trivial refinement (all points in one cluster)
- Density-based methods
- Graph-based clustering

# See Also
- [`DBscan`](@ref): DBSCAN clustering implementation
- [`Trivial`](@ref): Trivial (no clustering) implementation
"""
abstract type AbstractRefiner end
export AbstractRefiner

# function refine(X::MetricSpace, C::Covering, R::AbstractRefiner)
#     #! message about the need to implement this method for every
#     # subtype of AbstractRefiner
# end

include("common.jl")
export create_outlier_cluster,
    refine_cover

include("dbscan.jl")
export DBscan

include("trivial.jl")
export Trivial

end
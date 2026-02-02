"""
    Trivial <: AbstractRefiner

A trivial refiner that assigns all points to a single cluster.

The `Trivial` refiner is the simplest possible clustering method, assigning every point 
in each cover element to the same cluster (cluster 1). This effectively treats each 
cover element as a single, undivided cluster.

This is useful for testing purposes or when no clustering is desired within cover elements.

# Examples
```julia
using TDAmapper
X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0]])
trivial = Trivial()
clusters = trivial(X)  # Returns [1, 1, 1]
```

# See Also
- [`DBscan`](@ref): A more sophisticated clustering refiner
- [`AbstractRefiner`](@ref): Parent abstract type
"""
struct Trivial <: AbstractRefiner

end

"""
    (t::Trivial)(X::MetricSpace) -> Vector{Int}

Apply trivial clustering to a metric space.

# Arguments
- `X::MetricSpace`: The metric space to cluster

# Returns
- `Vector{Int}`: A vector of cluster assignments, all equal to 1

# Description
This function assigns all points in the metric space to cluster 1, effectively 
treating the entire space as a single cluster.
"""
function (t::Trivial)(X::MetricSpace)
    fill(1, length(X))
end

function TDAmapper.Refiners.refine_cover(X::MetricSpace, raw_cover::Covering, R::Trivial)
    raw_cover
end

@testitem "Trivial refiner" begin
    using TDAmapper
    using TDAmapper.Refiners

    # Test basic functionality
    X = [1.0, 2.0, 3.0] |> EuclideanSpace
    t = Trivial()
    clusters = t(X)
    @test clusters == [1, 1, 1]

    # Test with different sizes
    X2 = [[1.0, 2.0], [3.0, 4.0]] |> EuclideanSpace
    @test t(X2) == [1, 1]

    # Test refine_cover preserves input
    raw_cover = [[1, 2], [2, 3]]
    refined = refine_cover(X, raw_cover, t)
    @test refined == raw_cover

    # Test empty cover
    @test refine_cover(X, Vector{Int}[], t) == Vector{Int}[]
end

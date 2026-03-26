import Clustering as CL
using Distances

"""
    Hierarchical{T<:Real, M<:Distances.SemiMetric} <: AbstractRefiner

Hierarchical clustering refiner supporting multiple linkage methods.

Clusters points within each cover element using agglomerative hierarchical
clustering, cutting the dendrogram at a specified height threshold.

# Type Parameters
- `T<:Real`: The numeric type for the threshold parameter
- `M<:Distances.SemiMetric`: The concrete metric type

# Fields
- `linkage::Symbol=:single`: Linkage method. One of `:single`, `:complete`, `:average`, `:ward`, `:ward_presquared`.
- `threshold::T=0.5`: The height at which to cut the dendrogram.
- `metric::M=Euclidean()`: The distance metric to use.

# See Also
- [`SingleLinkage`](@ref), [`CompleteLinkage`](@ref), [`AverageLinkage`](@ref), [`WardLinkage`](@ref): Convenience constructors
"""
@kwdef struct Hierarchical{T<:Real, M<:Distances.SemiMetric} <: AbstractRefiner
    linkage::Symbol = :single
    threshold::T = 0.5
    metric::M = Euclidean()
end

"""
    (r::Hierarchical)(X::MetricSpace)

Apply hierarchical clustering to a metric space.

Returns cluster assignments as a `Vector{Int}`.
"""
function (r::Hierarchical)(X::MetricSpace)
    n = length(X)
    n == 1 && return [1]

    d = Distances.pairwise(r.metric, as_matrix(X), dims=2)
    hc = CL.hclust(d, linkage=r.linkage)
    CL.cutree(hc, h=r.threshold)
end

"""
    SingleLinkage(; threshold=0.5, metric=Euclidean())

Convenience constructor for [`Hierarchical`](@ref) with single linkage.

Single linkage merges clusters based on the minimum distance between any two points
in different clusters.
"""
SingleLinkage(; threshold=0.5, metric=Euclidean()) = Hierarchical(linkage=:single, threshold=threshold, metric=metric)

"""
    CompleteLinkage(; threshold=0.5, metric=Euclidean())

Convenience constructor for [`Hierarchical`](@ref) with complete linkage.

Complete linkage merges clusters based on the maximum distance between any two points
in different clusters.
"""
CompleteLinkage(; threshold=0.5, metric=Euclidean()) = Hierarchical(linkage=:complete, threshold=threshold, metric=metric)

"""
    AverageLinkage(; threshold=0.5, metric=Euclidean())

Convenience constructor for [`Hierarchical`](@ref) with average linkage.

Average linkage merges clusters based on the mean distance between all pairs of points
in different clusters.
"""
AverageLinkage(; threshold=0.5, metric=Euclidean()) = Hierarchical(linkage=:average, threshold=threshold, metric=metric)

"""
    WardLinkage(; threshold=0.5, metric=Euclidean())

Convenience constructor for [`Hierarchical`](@ref) with Ward's method.

Ward's method merges clusters to minimize the total within-cluster variance.
"""
WardLinkage(; threshold=0.5, metric=Euclidean()) = Hierarchical(linkage=:ward, threshold=threshold, metric=metric)

@testitem "Hierarchical refiner" begin
    using TDAmapper
    using TDAmapper.Refiners

    # Two well-separated clusters
    X = EuclideanSpace([[0.0, 0.0], [0.1, 0.0], [0.0, 0.1], [10.0, 10.0], [10.1, 10.0], [10.0, 10.1]])

    # With a large threshold, everything is one cluster
    r = Hierarchical(linkage=:single, threshold=100.0)
    @test length(unique(r(X))) == 1

    # With a small threshold, two clusters emerge
    r = Hierarchical(linkage=:single, threshold=1.0)
    clusters = r(X)
    @test length(unique(clusters)) == 2
    @test clusters[1] == clusters[2] == clusters[3]
    @test clusters[4] == clusters[5] == clusters[6]
    @test clusters[1] != clusters[4]

    # Complete linkage also works
    r = CompleteLinkage(threshold=1.0)
    clusters = r(X)
    @test length(unique(clusters)) == 2

    # Single point
    X1 = EuclideanSpace([[1.0, 2.0]])
    @test Hierarchical()(X1) == [1]

    # Convenience constructors produce Hierarchical
    @test SingleLinkage() isa Hierarchical
    @test CompleteLinkage() isa Hierarchical
    @test AverageLinkage() isa Hierarchical
    @test WardLinkage() isa Hierarchical

    @test SingleLinkage().linkage == :single
    @test CompleteLinkage().linkage == :complete
    @test AverageLinkage().linkage == :average
    @test WardLinkage().linkage == :ward
end

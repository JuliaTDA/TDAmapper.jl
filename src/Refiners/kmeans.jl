import Clustering as CL
using Distances

"""
    KMeans{M<:Distances.SemiMetric} <: AbstractRefiner

K-means clustering refiner.

Partitions points within each cover element into `k` clusters by minimizing
within-cluster sum of squared distances to centroids.

# Fields
- `k::Int=2`: Number of clusters.
- `metric::M=Euclidean()`: The distance metric to use.
- `maxiter::Int=100`: Maximum number of iterations.

# Notes
When a cover element has fewer points than `k`, the number of clusters is
automatically clamped to the number of points.
"""
@kwdef struct KMeans{M<:Distances.SemiMetric} <: AbstractRefiner
    k::Int = 2
    metric::M = Euclidean()
    maxiter::Int = 100
end

"""
    (r::KMeans)(X::MetricSpace)

Apply k-means clustering to a metric space.

Returns cluster assignments as a `Vector{Int}`.
"""
function (r::KMeans)(X::MetricSpace)
    n = length(X)
    n == 1 && return [1]
    k_actual = min(r.k, n)
    CL.kmeans(as_matrix(X), k_actual; distance=r.metric, maxiter=r.maxiter).assignments
end

@testitem "KMeans refiner" begin
    using TDAmapper
    using TDAmapper.Refiners

    # Two well-separated clusters
    X = EuclideanSpace([[0.0, 0.0], [0.1, 0.0], [0.0, 0.1], [10.0, 10.0], [10.1, 10.0], [10.0, 10.1]])
    r = KMeans(k=2)
    clusters = r(X)
    @test length(unique(clusters)) == 2
    @test clusters[1] == clusters[2] == clusters[3]
    @test clusters[4] == clusters[5] == clusters[6]

    # k > n is clamped
    X_small = EuclideanSpace([[1.0, 2.0], [3.0, 4.0]])
    r_big = KMeans(k=10)
    clusters = r_big(X_small)
    @test length(clusters) == 2
    @test length(unique(clusters)) <= 2

    # Single point
    X1 = EuclideanSpace([[1.0, 2.0]])
    @test r(X1) == [1]
end

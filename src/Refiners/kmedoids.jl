import Clustering as CL
using Distances

"""
    KMedoids{M<:Distances.SemiMetric} <: AbstractRefiner

K-medoids clustering refiner.

Partitions points within each cover element into `k` clusters by selecting
actual data points as cluster centers (medoids), minimizing the sum of
distances from each point to its nearest medoid.

Unlike [`KMeans`](@ref), this operates on a pairwise distance matrix rather
than coordinates, making it suitable for non-Euclidean spaces where centroids
may not be meaningful.

# Fields
- `k::Int=2`: Number of clusters.
- `metric::M=Euclidean()`: The distance metric to use.
- `maxiter::Int=100`: Maximum number of iterations.

# Notes
When a cover element has fewer points than `k`, the number of clusters is
automatically clamped to the number of points.
"""
@kwdef struct KMedoids{M<:Distances.SemiMetric} <: AbstractRefiner
    k::Int = 2
    metric::M = Euclidean()
    maxiter::Int = 100
end

"""
    (r::KMedoids)(X::MetricSpace)

Apply k-medoids clustering to a metric space.

Returns cluster assignments as a `Vector{Int}`.
"""
function (r::KMedoids)(X::MetricSpace)
    n = length(X)
    n == 1 && return [1]
    k_actual = min(r.k, n)
    d = Distances.pairwise(r.metric, as_matrix(X), dims=2)
    CL.kmedoids(d, k_actual; maxiter=r.maxiter).assignments
end

@testitem "KMedoids refiner" begin
    using TDAmapper
    using TDAmapper.Refiners

    # Two well-separated clusters
    X = EuclideanSpace([[0.0, 0.0], [0.1, 0.0], [0.0, 0.1], [10.0, 10.0], [10.1, 10.0], [10.0, 10.1]])
    r = KMedoids(k=2)
    clusters = r(X)
    @test length(unique(clusters)) == 2
    @test clusters[1] == clusters[2] == clusters[3]
    @test clusters[4] == clusters[5] == clusters[6]

    # k > n is clamped
    X_small = EuclideanSpace([[1.0, 2.0], [3.0, 4.0]])
    r_big = KMedoids(k=10)
    clusters = r_big(X_small)
    @test length(clusters) == 2
    @test length(unique(clusters)) <= 2

    # Single point
    X1 = EuclideanSpace([[1.0, 2.0]])
    @test r(X1) == [1]
end

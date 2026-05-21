import NearestNeighbors as NN
using Distances
import Clustering as CL
using LinearAlgebra

"""
    SpectralRefiner{M<:Distances.SemiMetric} <: AbstractRefiner

Spectral clustering via graph Laplacian eigenvectors.

Constructs a k-NN similarity graph on the cover element's points, computes the
normalized graph Laplacian's k smallest eigenvectors, and runs k-means in that
eigenspace. Finds non-convex clusters where DBSCAN and k-means fail.

# Fields
- `k::Int=2`: Number of clusters.
- `n_neighbors::Int=10`: Number of nearest neighbors for the similarity graph.
- `metric::M=Euclidean()`: Distance metric.
"""
@kwdef struct SpectralRefiner{M<:Distances.SemiMetric} <: AbstractRefiner
    k::Int = 2
    n_neighbors::Int = 10
    metric::M = Euclidean()
end

"""
    (r::SpectralRefiner)(X::MetricSpace)

Apply spectral clustering to a metric space.

Returns cluster assignments as a `Vector{Int}`.
"""
function (r::SpectralRefiner)(X::MetricSpace)
    n = length(X)
    n == 1 && return [1]
    n <= r.k && return collect(1:n)

    mat = as_matrix(X)
    nn = min(r.n_neighbors, n - 1)
    k_actual = min(r.k, n)

    # Build k-NN similarity graph (binary adjacency)
    tree = NN.KDTree(mat, r.metric)
    idxs, _ = NN.knn(tree, mat, nn + 1, true)

    W = zeros(Float64, n, n)
    for i in 1:n
        for j in idxs[i]
            j == i && continue
            W[i, j] = 1.0
            W[j, i] = 1.0
        end
    end

    # Normalized graph Laplacian: L = I - D^{-1/2} W D^{-1/2}
    d = vec(sum(W, dims=2))
    d_inv_sqrt = [di > 0 ? 1.0 / sqrt(di) : 0.0 for di in d]
    D_inv_sqrt = Diagonal(d_inv_sqrt)
    L = I - D_inv_sqrt * W * D_inv_sqrt

    # k smallest eigenvectors (by eigenvalue magnitude)
    _, vecs = eigen(Symmetric(L))
    U = vecs[:, 1:k_actual]  # n × k_actual matrix of eigenvectors

    # Normalize rows to unit length (standard spectral clustering step)
    for i in 1:n
        row_norm = LinearAlgebra.norm(U[i, :])
        row_norm > 1e-10 && (U[i, :] ./= row_norm)
    end

    # k-means in eigenspace
    CL.kmeans(U', k_actual).assignments
end

function TDAmapper.validate(r::SpectralRefiner)
    r.k >= 1 || throw(MapperArgumentError("SpectralRefiner — k must be >= 1, got $(r.k)"))
    r.n_neighbors >= 1 || throw(MapperArgumentError("SpectralRefiner — n_neighbors must be >= 1, got $(r.n_neighbors)"))
    return nothing
end

@testitem "SpectralRefiner" begin
    using TDAmapper
    using TDAmapper.Refiners

    # Two well-separated clusters
    X = EuclideanSpace([[0.0, 0.0], [0.1, 0.0], [0.0, 0.1], [10.0, 10.0], [10.1, 10.0], [10.0, 10.1]])
    r = SpectralRefiner(k=2, n_neighbors=2)
    clusters = r(X)
    @test length(unique(clusters)) == 2
    @test clusters[1] == clusters[2] == clusters[3]
    @test clusters[4] == clusters[5] == clusters[6]

    # Single point
    X1 = EuclideanSpace([[1.0, 2.0]])
    @test SpectralRefiner()(X1) == [1]

    # Validate
    @test_throws MapperArgumentError validate(SpectralRefiner(k=0))
    @test_throws MapperArgumentError validate(SpectralRefiner(n_neighbors=0))
    @test isnothing(validate(SpectralRefiner(k=2, n_neighbors=5)))
end

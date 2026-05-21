import NearestNeighbors as NN
using Distances

"""
    OPTICSRefiner{M<:Distances.SemiMetric} <: AbstractRefiner

Variable-density clustering using local core distances.

Each point's neighborhood radius is its distance to its `min_neighbors`-th nearest
neighbor. Points are connected if they fall within each other's core distance,
making this robust to varying data density unlike DBSCAN's fixed radius.

# Fields
- `min_neighbors::Int=5`: Number of nearest neighbors used to estimate core distance.
- `metric::M=Euclidean()`: Distance metric.

# Notes
This is a simplified OPTICS-inspired method. It automatically adapts to local density
by using per-point radii rather than a global epsilon.
"""
@kwdef struct OPTICSRefiner{M<:Distances.SemiMetric} <: AbstractRefiner
    min_neighbors::Int = 5
    metric::M = Euclidean()
end

"""
    (r::OPTICSRefiner)(X::MetricSpace)

Apply OPTICS-inspired variable-density clustering to a metric space.

Returns cluster assignments as a `Vector{Int}`.
"""
function (r::OPTICSRefiner)(X::MetricSpace)
    n = length(X)
    n == 1 && return [1]
    n <= r.min_neighbors && return fill(1, n)

    mat = as_matrix(X)
    k = min(r.min_neighbors, n - 1)
    tree = NN.KDTree(mat, r.metric)

    # Core distance for each point = distance to k-th nearest neighbor
    idxs, dists = NN.knn(tree, mat, k + 1, true)  # +1 because point finds itself
    core_dists = [d[end] for d in dists]

    # Build adjacency: i and j are connected if dist(i,j) <= min(core_dist[i], core_dist[j])
    # This creates a "mutual reachability" graph
    adj = [Int[] for _ in 1:n]
    for i in 1:n
        # Only check neighbors within core_dist[i] (already found by knn)
        for (j, d) in zip(idxs[i], dists[i])
            j == i && continue
            if d <= core_dists[i] && d <= core_dists[j]
                push!(adj[i], j)
                push!(adj[j], i)
            end
        end
    end

    # Find connected components = clusters
    labels = zeros(Int, n)
    cluster_id = 0
    for i in 1:n
        labels[i] != 0 && continue
        cluster_id += 1
        queue = [i]
        while !isempty(queue)
            v = pop!(queue)
            labels[v] != 0 && continue
            labels[v] = cluster_id
            for w in adj[v]
                labels[w] == 0 && push!(queue, w)
            end
        end
    end
    labels
end

function TDAmapper.validate(r::OPTICSRefiner)
    r.min_neighbors >= 1 || throw(MapperArgumentError("OPTICSRefiner — min_neighbors must be >= 1, got $(r.min_neighbors)"))
    return nothing
end

@testitem "OPTICSRefiner" begin
    using TDAmapper
    using TDAmapper.Refiners

    # Two well-separated clusters
    X = EuclideanSpace([[0.0, 0.0], [0.1, 0.0], [0.0, 0.1], [10.0, 10.0], [10.1, 10.0], [10.0, 10.1]])
    r = OPTICSRefiner(min_neighbors=2)
    clusters = r(X)
    @test length(unique(clusters)) == 2
    @test clusters[1] == clusters[2] == clusters[3]
    @test clusters[4] == clusters[5] == clusters[6]
    @test clusters[1] != clusters[4]

    # Single point
    X1 = EuclideanSpace([[1.0, 2.0]])
    @test OPTICSRefiner()(X1) == [1]

    # Validate
    @test_throws MapperArgumentError validate(OPTICSRefiner(min_neighbors=0))
    @test isnothing(validate(OPTICSRefiner(min_neighbors=3)))
end

import Clustering as CL
using Distances

"""
    FirstEmptyBin{M<:Distances.SemiMetric} <: AbstractRefiner

Clustering refiner using the "cutoff at first empty bin" heuristic from the
original TDAmapper R package by Paul Pearson.

Performs single-linkage hierarchical clustering with an automatically determined
threshold: the dendrogram merge heights are binned into a histogram, and the
cutoff is set at the midpoint of the first empty bin. If no empty bin exists,
all points are assigned to a single cluster.

# Fields
- `num_bins::Int=10`: Number of histogram bins for the merge heights.
- `metric::M=Euclidean()`: The distance metric to use.

# References
- Pearson, P. "TDAmapper" R package: `cluster_cutoff_at_first_empty_bin`
"""
@kwdef struct FirstEmptyBin{M<:Distances.SemiMetric} <: AbstractRefiner
    num_bins::Int = 10
    metric::M = Euclidean()
end

"""
    cutoff_at_first_empty_bin(heights, diam, num_bins) -> Real

Compute the clustering cutoff by finding the first empty bin in a histogram
of dendrogram merge heights.

Returns `Inf` if there is no empty bin (all points in one cluster).
"""
function cutoff_at_first_empty_bin(heights, diam, num_bins)
    length(heights) == 1 && heights[1] == diam && return Inf

    lo = minimum(heights)
    bin_width = (diam - lo) / num_bins

    bin_width == 0 && return Inf

    # Build histogram counts
    counts = zeros(Int, num_bins)
    for h in heights
        idx = clamp(ceil(Int, (h - lo) / bin_width), 1, num_bins)
        counts[idx] += 1
    end
    # The diameter itself falls in the last bin
    counts[end] += 1

    # Find first empty bin
    empty_idx = findfirst(==(0), counts)
    isnothing(empty_idx) && return Inf

    # Return midpoint of the empty bin
    lo + (empty_idx - 0.5) * bin_width
end

"""
    (r::FirstEmptyBin)(X::MetricSpace)

Apply the first-empty-bin clustering to a metric space.

Returns cluster assignments as a `Vector{Int}`.
"""
function (r::FirstEmptyBin)(X::MetricSpace)
    n = length(X)
    n == 1 && return [1]

    d = Distances.pairwise(r.metric, as_matrix(X), dims=2)
    hc = CL.hclust(d, linkage=:single)
    diam = maximum(d)
    cutoff = cutoff_at_first_empty_bin(hc.heights, diam, r.num_bins)
    CL.cutree(hc, h=cutoff)
end

@testitem "FirstEmptyBin refiner" begin
    using TDAmapper
    using TDAmapper.Refiners

    # Two well-separated clusters should be split
    X = EuclideanSpace([[0.0, 0.0], [0.1, 0.0], [10.0, 10.0], [10.1, 10.0]])
    r = FirstEmptyBin(num_bins=10)
    clusters = r(X)
    @test length(unique(clusters)) == 2
    @test clusters[1] == clusters[2]
    @test clusters[3] == clusters[4]
    @test clusters[1] != clusters[3]

    # Tightly packed points -> one cluster
    X_tight = EuclideanSpace([[0.0, 0.0], [0.01, 0.0], [0.0, 0.01], [0.01, 0.01]])
    clusters_tight = r(X_tight)
    @test length(unique(clusters_tight)) == 1

    # Single point
    X1 = EuclideanSpace([[1.0, 2.0]])
    @test r(X1) == [1]
end

@testitem "cutoff_at_first_empty_bin" begin
    using TDAmapper.Refiners: cutoff_at_first_empty_bin

    # Heights with a clear gap
    heights = [0.1, 0.2, 0.3, 5.0]
    diam = 5.0
    cutoff = cutoff_at_first_empty_bin(heights, diam, 10)
    @test cutoff < 5.0
    @test cutoff > 0.3

    # No gap -> Inf
    heights_dense = collect(range(0.1, 1.0, length=20))
    @test cutoff_at_first_empty_bin(heights_dense, 1.0, 10) == Inf

    # Single height equal to diameter -> Inf
    @test cutoff_at_first_empty_bin([1.0], 1.0, 10) == Inf
end

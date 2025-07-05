"""
    create_outlier_cluster(x)

Replaces all occurrences of `0` in the input array `x` with a value one greater than the current maximum of `x`.
If there are no zeros in `x`, the array is returned unchanged.

# Arguments
- `x`: An array of numeric values.

# Returns
- An array where all zeros have been replaced by `maximum(x) + 1`, or the original array if no zeros are present.
"""
function create_outlier_cluster(x)
    if any(==(0), x)
        x = replace(x, 0 => maximum(x) + 1)
    end

    x
end

@testitem "create_outlier_cluster" begin
    using TDAmapper.ClusteringMethods

    x = [1, 2, 3]
    @test create_outlier_cluster(x) == x

    x[end] = 0
    @test create_outlier_cluster(x) == [1, 2, 3]

    x = [1, 1, 0]
    @test create_outlier_cluster(x) == [1, 1, 2]

    x = [0, 0, 0]
    @test create_outlier_cluster(x) == [1, 1, 1]
end

"""
    split_covering(
    X::MetricSpace, C::Covering; clustering=ClusteringMethods.DBscan()
)

Splits each element of a covering `C` of a metric space `X` into clusters using the specified clustering algorithm.

# Arguments
- `X::MetricSpace`: The metric space containing the data points.
- `C::Covering`: A collection of index sets, each representing a subset (cover) of `X`.
- `clustering`: (Optional) A clustering function to apply to each subset of `X` defined by the covering. Defaults to `cluster_dbscan`.

# Returns
- A collection where each element corresponds to a cover in `C`, further split into clusters according to the clustering algorithm. Each cluster is represented by the indices of the points in `X` belonging to that cluster.
"""
function split_covering(
    X::MetricSpace, C::Covering; clustering=ClusteringMethods.DBscan()
)
    splitted_pb = map(C) do ids
        # cluster each element of the pullback
        cl = clustering(X[ids])

        # split the pre image
        map(unique_sort(cl)) do ucls
            ids[findall(==(ucls), cl)]
        end
    end

    splitted_pb
end

"""
    reduce_covering(splitted_pb)

Reduces a collection of collections (such as the output of `split_covering`) into a single collection by concatenating all inner collections.

# Arguments
- `splitted_pb`: A collection of collections (e.g., clusters from multiple covers).

# Returns
- A single collection containing all elements from the input collections, concatenated together.
"""
function reduce_covering(splitted_pb)
    reduce(vcat, splitted_pb)
end
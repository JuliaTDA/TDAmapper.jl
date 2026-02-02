import Clustering as CL
using Distances

"""
    DBscan{T<:Real, M<:Distances.SemiMetric}

A struct for configuring the DBSCAN clustering algorithm.

# Type Parameters
- `T<:Real`: The numeric type for the radius parameter
- `M<:Distances.SemiMetric`: The concrete metric type

# Fields
- `radius::T=0.1`: The maximum distance between two samples for them to be considered as in the same neighborhood.
- `metric::M`: The distance metric to use (default is `Euclidean()`).
- `min_neighbors::Int=1`: The minimum number of neighbors required for a point to be considered a core point.
- `min_cluster_size::Int=1`: The minimum number of points required to form a cluster.
"""
@kwdef struct DBscan{T<:Real, M<:Distances.SemiMetric} <: AbstractRefiner
    radius::T = 0.1
    metric::M = Euclidean()
    min_neighbors::Int = 1
    min_cluster_size::Int = 1
end

"""
    (cl::DBscan)(X::MetricSpace)

Apply the DBSCAN clustering algorithm to a `MetricSpace` object `X` using the parameters specified in the `DBscan` struct.

# Arguments
- `X::MetricSpace`: The input data as a `MetricSpace` object.

# Returns
- Cluster assignments as an array, with outliers assigned to a separate cluster.
"""
function (cl::DBscan)(X::MetricSpace)
    CL.dbscan(
        as_matrix(X), cl.radius
        ; metric=cl.metric, min_neighbors=cl.min_neighbors,
        min_cluster_size=cl.min_cluster_size
    ).assignments |>
    create_outlier_cluster
end

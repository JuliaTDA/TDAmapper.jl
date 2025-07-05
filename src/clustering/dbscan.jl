import Clustering as CL
using Distances

"""
    DBscan

A struct for configuring the DBSCAN clustering algorithm.

# Fields
- `radius::Real=0.1`: The maximum distance between two samples for them to be considered as in the same neighborhood.
- `metric`: The distance metric to use (default is `Euclidean()`).
- `min_neighbors::Integer=1`: The minimum number of neighbors required for a point to be considered a core point.
- `min_cluster_size::Integer=1`: The minimum number of points required to form a cluster.
"""
@kwdef struct DBscan
    radius::Real = 0.1
    metric = Euclidean()
    min_neighbors::Integer = 1
    min_cluster_size::Integer = 1
end

"""
    (cl::DBscan)(X::MetricSpace)

Apply the DBSCAN clustering algorithm to a `MetricSpace` object `X` using the parameters specified in the `DBscan` struct.

# Arguments
- `X::MetricSpace`: The input data as a `MetricSpace` object.

# Returns
- Cluster assignments as an array, with outliers assigned to a separate cluster.
"""
function (cl::DBscan)(X)
    CL.dbscan(
        as_matrix(X), cl.radius
        ; metric=cl.metric, min_neighbors=cl.min_neighbors,
        min_cluster_size=cl.min_cluster_size
    ).assignments |>
    create_outlier_cluster
end


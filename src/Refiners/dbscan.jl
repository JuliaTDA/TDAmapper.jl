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

function TDAmapper.validate(r::DBscan)
    r.radius > 0 || throw(MapperArgumentError("DBscan — radius must be > 0, got $(r.radius)"))
    r.min_neighbors >= 1 || throw(MapperArgumentError("DBscan — min_neighbors must be >= 1, got $(r.min_neighbors)"))
    r.min_cluster_size >= 1 || throw(MapperArgumentError("DBscan — min_cluster_size must be >= 1, got $(r.min_cluster_size)"))
    return nothing
end

@testitem "validate DBscan" begin
    using TDAmapper
    using TDAmapper.Refiners
    @test_throws MapperArgumentError validate(DBscan(radius=-1.0))
    @test_throws MapperArgumentError validate(DBscan(radius=0.0))
    @test_throws MapperArgumentError validate(DBscan(min_neighbors=0))
    @test_throws MapperArgumentError validate(DBscan(min_cluster_size=0))
    @test isnothing(validate(DBscan(radius=0.5, min_neighbors=2, min_cluster_size=1)))
end

using TDAmapper.ClusteringMethods: split_covering

"""
    mapper(
    X::MetricSpace, filter_values::Vector{<:Real}, covering_intervals::Vector{<:Interval}
    ; clustering=cluster_dbscan, nerve_function=nerve_1d
)
        X::MetricSpace, 
        filter_values::Vector{<:Real}, 
        covering_intervals::Vector{<:Interval};
        clustering=cluster_dbscan, 
        nerve_function=nerve_1d
    ) -> Mapper

Constructs a Mapper object from a metric space using the Mapper algorithm.

# Arguments
- `X::MetricSpace`: The input metric space containing the data points.
- `filter_values::Vector{<:Real}`: The values of the filter function evaluated on the data points in `X`.
- `covering_intervals::Vector{<:Interval}`: A collection of intervals that cover the range of the filter values.
- `clustering`: (Optional) A clustering function to apply to the pre-images of the covering intervals. Defaults to `cluster_dbscan`.
- `nerve_function`: (Optional) A function to compute the nerve (graph) of the covering. Defaults to `nerve_1d`.

# Returns
- `Mapper`: An object containing the covered metric space and the resulting nerve graph.

# Description
This function implements the Mapper algorithm for topological data analysis. It first computes the pullback of the covering intervals via the filter values, clusters the data points in each pre-image, constructs a covered metric space, and then computes the nerve (graph) of the covering. The result is returned as a `Mapper` object.
"""
function mapper(
    X::MetricSpace, filter_values::Vector{<:Real}, image_cover::Vector{<:Interval}
    ; clustering=ClusteringMethods.DBscan(), nerve_function=nerve_1d
)
    # calculate the pullback
    pb_cover = pullback(filter_values, image_cover)

    # cluster each pre-image
    splitted_pb = split_covering(X, pb_cover, clustering=clustering)

    covering = ClusteringMethods.reduce_covering(splitted_pb)

    g = nerve_function(covering)

    Mapper(X=X, C=covering, g=g)
end

@testitem "mapper" begin
    using TDAmapper
    import Graphs

    X = sphere(1000, dim=2)
    fv = first.(X)
    image_covering = uniform(fv, length=3, expansion=0.3)
    clustering = ClusteringMethods.DBscan(radius=0.1)

    M = mapper(X, fv, image_covering, clustering=clustering)
    @test M.X == X    
    @test Graphs.nv(M.g) == 4
    @test Graphs.ne(M.g) == 4
end
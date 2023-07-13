"""
mapper(
    X::PointCloud
    ,filter_values::Vector{<:Real}
    ,covering_intervals::Vector{<:Interval}
    ;clustering = cluster_dbscan
    )

Create the mapper graph of a given pointcloud `X`,
with a vector of `filter_values`, using the
`covering_intervals` and a `clustering` function.

# Examples

etc.
"""
function mapper(
    X::PointCloud
    ,filter_values::Vector{<:Real}
    ,covering_intervals::Vector{<:Interval}
    ;clustering = cluster_dbscan
    )

    # calculate the pullback
    id_pbs = pre_image_id(filter_values, covering_intervals)
    
    # cluster each pre-image
    clustered_pb_ids, node_origin = split_pre_image(X, id_pbs, clustering = clustering)
    
    # create the mapper graph
    adj_matrix = adj_matrix_from_pb(clustered_pb_ids)
    
    mapper_graph = Graphs.Graph(adj_matrix)

    mapper = Mapper(
        X = X
        ,filter_values = filter_values
        ,covering_intervals = covering_intervals
        ,clustering = clustering
        ,clustered_pb_ids = clustered_pb_ids
        ,node_origin = node_origin
        ,adj_matrix = adj_matrix
        ,mapper_graph = mapper_graph
        )
end
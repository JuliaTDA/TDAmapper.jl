# Mapper
# function mapper(
#     X::Matrix; 
#     data = nothing
#     ,filter_values = nothing
#     ,filter_function = excentricity
#     ,covering = nothing
#     ,covering_function = x -> uniform(x, 10, 100)
#     ,clustering_function = nothing
#     )

#     if data === nothing
#         data = DataFrame(X, :auto) #! checar se X é dataframe antes? #! fazer dispatch separado?
#     end

#     if filter_values === nothing
#         filter_values = X |> excentricity
#     end
 
#     if covering === nothing
#         covering = covering_function(filter_values)
#     end
        
#     id_pbs = pre_image_id(filter_values, covering)
    
#     clustered_pb_ids, node_origin = split_pre_image(X, id_pbs)
    
#     clustered_pb_ids
    
#     adj_matrix = adj_matrix_from_pb(clustered_pb_ids)
    
#     mapper_graph = Graph(adj_matrix)

#     mapper = Mapper(
#         X = X
#         ,data = data
#         ,filter_function = filter_function
#         ,filter_values = filter_values
#         ,covering = covering, covering_function = covering_function
#         ,clustering_function = clustering_function
#         ,clustered_pb_ids = clustered_pb_ids
#         ,node_origin = node_origin
#         ,mapper_graph = mapper_graph
#         )
# end

# using ..TDAmapper

"""
    mapper(X, filter_values, covering_intervals, clustering)

Create the mapper graph of a given pointcloud `X`,
with a vector of `filter_values`, using the
`covering_intervals` and a `clustering` function.
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
    
    mapper_graph = Graph(adj_matrix)

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
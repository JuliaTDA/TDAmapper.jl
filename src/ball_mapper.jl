function ball_mapper(X::PointCloud, L::Vector{<:Integer}; ϵ = 1)
    balltree = BallTree(X)
    covering = inrange(balltree, X[:, L], ϵ)
    adj_matrix = adj_matrix_from_covering(covering)

    mapper_graph = Graphs.Graph(adj_matrix)

    mp = BallMapper(
        X = X
        ,L = L
        ,clustering = identity
        ,points_in_node = covering
        ,node_origin = covering
        ,adj_matrix = adj_matrix
        ,mapper_graph = mapper_graph
    )
end

# function ball_mapper(X::PointCloud, f::Function)    
#     covering = f(X)
#     adj_matrix = adj_matrix_from_covering(covering)

#     mapper_graph = Graphs.Graph(adj_matrix)

#     mp = BallMapper(
#         X = X
#         ,L = L
#         ,clustering = identity
#         ,points_in_node = covering
#         ,node_origin = covering
#         ,adj_matrix = adj_matrix
#         ,mapper_graph = mapper_graph
#     )
# end
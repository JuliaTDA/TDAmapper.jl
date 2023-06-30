using TDAmapper

X = Datasets.circle(1000)
excentricity(X)

# covering
fv = rand(1000)
uniform(fv)

[range(1, 1, length = 10)...] |> collect

# mapper.jl
X = Datasets.circle(1000)
fv = excentricity(X)
fv = X[:, 1]
cv = uniform(fv)
filter_values = fv
covering_intervals = cv

# Mapper
function mapper2(
    X::PointCloud
    ,filter_values::Vector{<:Real}
    ,covering_intervals::Vector{<:Interval}
    ;clustering = uniform(length = 12, overlap = 100)    
    )

    id_pbs = pre_image_id(filter_values, covering_intervals)
    
    clustered_pb_ids, node_origin = split_pre_image(X, id_pbs)
    
    adj_matrix = adj_matrix_from_pb(clustered_pb_ids)
    
    mapper_graph = Graph(adj_matrix)    

    mp = Mapper(
        X = X
        ,filter_values = filter_values
        ,covering_intervals = covering_intervals
        ,filter_values = filter_values
        ,clustering = clustering
        ,clustered_pb_ids = clustered_pb_ids
        ,node_origin = node_origin
        ,adj_matrix = adj_matrix
        ,mapper_graph = mapper_graph
        )

    return mapper
    
end
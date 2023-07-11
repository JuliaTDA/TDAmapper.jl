import Clustering

"""
    cluster_set

"""
function cluster_dbscan(
    X::PointCloud
    ;radius = 0.1, metric = Euclidean()
    ,min_neighbors::Integer = 1
    ,min_cluster_size::Integer = 1
    )
    cl = try
        Clustering.dbscan(
            X, radius, metric = metric
            ;min_neighbors = min_neighbors
            ,min_cluster_size = min_cluster_size
            ).assignments
    catch
        repeat([1], size(X)[2])
    end

    return cl
end

function cluster_dbscan(
    ;radius = 0.1, metric = Euclidean()
    ,min_neighbors::Integer = 1
    ,min_cluster_size::Integer = 1
    )
    x -> cluster_dbscan(
        x, radius = radius, metric = metric, min_neighbors = min_neighbors
        ,min_cluster_size = min_cluster_size
        )
end

"""
    split_pre_image

"""
function split_pre_image(
    X::PointCloud, id_pbs; clustering = cluster_dbscan
    )
    clustered_pb_ids = []
    node_origin = String[]

    @showprogress "Splitting pre images..." for i ∈ eachindex(id_pbs)

        # store the pre image
        pb = X[:, id_pbs[i]]
    
        # store the cluster of each point
        cl = clustering(pb)
        
        # split the pre image according to the clustering algorithm
        for cluster_id ∈ unique_sort(cl)
            ids = findall(==(cluster_id), cl)
            s = id_pbs[i][ids]
            push!(clustered_pb_ids, s)
            push!(node_origin, "$(i)-$(cluster_id)")
        end    
    end    

    return clustered_pb_ids, node_origin
end
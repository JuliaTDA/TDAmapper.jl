"""
    cluster_set

"""
function cluster_dbscan(X::PointCloud; radius = 0.1, metric = Euclidean())
    cl = try
        dbscan(transpose(X), radius, metric = metric).assignments
    catch
        repeat([1], size(X)[1])
    end
end

function cluster_dbscan(radius = 0.1, metric = Euclidean())
    x -> cluster_dbscan(x, radius = radius, metric = metric)
end

"""
    split_pre_image

"""
function split_pre_image(
    X::PointCloud, id_pbs; clustering = cluster_dbscan
    )
    clustered_pb_ids = []
    node_origin = Int32[]

    @showprogress "Splitting pre images..." for i ∈ eachindex(id_pbs)

        # store the pre image
        pb = X[id_pbs[i], :]
    
        # store the cluster of each point
        cl = cluster_dbscan(pb)
        
        # split the pre image according to the clustering algorithm
        for cluster_id ∈ unique_sort(cl)
            ids = findall(==(cluster_id), cl)
            s = id_pbs[i][ids]
            push!(clustered_pb_ids, s)
            push!(node_origin, i)
        end    
    end    

    return clustered_pb_ids, node_origin
end
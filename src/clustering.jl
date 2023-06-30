"""
    cluster_set

"""
function cluster_set(X::PointCloud; metric = Euclidean())
    cl = try
        dbscan(transpose(X), 0.1, metric = metric).assignments
    catch
        repeat([1], size(X)[1])
    end
end
"""
    split_pre_image

"""
function split_pre_image(X::PointCloud, id_pbs)
    clustered_pb_ids = []
    node_origin = Int32[]

    @showprogress "Splitting pre images..." for i ∈ eachindex(id_pbs)

        # store the pre image
        pb = X[id_pbs[i], :]
    
        # store the cluster of each point
        cl = cluster_set(pb)
        
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
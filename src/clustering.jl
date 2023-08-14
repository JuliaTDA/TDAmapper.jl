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

function split_covering(
    CX::CoveredPointCloud; clustering = cluster_dbscan
    )
    first_covering = CX.covering

    final_covering = []
    
    ids = first_covering[1]
    
    vv = map(first_covering) do ids
        # store the pullback
       pb = CX.X[:, ids]
    
       # store the cluster of each point
       cl = clustering(pb)
        
       # split the pre image according to the clustering algorithm
       map(unique_sort(cl)) do ucls
           ids[findall(==(ucls), cl)]
       end
    
    end
    
    return mapreduce(vcat, vcat,  vv)
end
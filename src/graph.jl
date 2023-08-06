"""
Create the adjacent matrix from a covering
"""
function adj_matrix_from_covering(covering::Covering)
    n = length(covering)
    adj_matrix = zeros(Int32, n, n)

    @showprogress "Calculating edges..." for i ∈ eachindex(covering)
        @threads for j ∈ eachindex(covering)

            i < j && continue

            if !isdisjoint(covering[i], covering[j])
                adj_matrix[i, j] = 1            
                adj_matrix[j, i] = 1
            end
        end
    end
    return adj_matrix
end

"""
Create the adjacent matrix from a pullback
"""
function adj_matrix_from_pb(clustered_pb_ids)
    n = size(clustered_pb_ids)[1]
    adj_matrix = zeros(Int32, n, n)
    @showprogress "Calculating edges" for i ∈ eachindex(clustered_pb_ids)
        @threads for j ∈ eachindex(clustered_pb_ids)
             i >= j && continue
             u, v = clustered_pb_ids[i], clustered_pb_ids[j]
             if !isdisjoint(u, v)
                adj_matrix[i, j], adj_matrix[j, i] = 1, 1            
             end
        end    
    end

    return(adj_matrix)    
end

"""

    mds_layout(CX::CoveredPointCloud, dim::Integer = 2)

Create the MDS layout of a covered space using the centroid of each element of the covering
"""
function mds_layout(CX::CoveredPointCloud; dim::Integer = 2)
    @assert dim ∈ [2, 3] "dim must be 2 or 3!"
    ctd = centroid(CX)
    M = fit(MDS, ctd, distances = false, maxoutdim = dim)    
    md = predict(M)
    
    pos = [Point{dim}(x) for x ∈ eachcol(md)]

    return pos
end
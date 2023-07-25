"""
Create the adjacent matrix from a covering
"""
function adj_matrix_from_covering(covering::CoveringIds)
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
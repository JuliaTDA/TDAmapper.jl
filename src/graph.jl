# adj matrix
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
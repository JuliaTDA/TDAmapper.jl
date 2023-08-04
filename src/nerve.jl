function centroid(mp::AbstractMapper)
    map(bmp.points_in_node) do ids
        map(mean, eachrow(bmp.X[:, ids]))
    end
end

has_intersection(x, y; kwargs...) = !isdisjoint(x, y)

"""
Create the adjacent matrix from a covering
"""
function nerve_1d(X::PointCloud, covering::CoveringIds; predicate = nothing)

    if isnothing(predicate)
        predicate = has_intersection(x, y, kwargs)
    end

    n = length(covering)
    adj_matrix = zeros(Int64, n, n)

    @showprogress "Calculating edges..." for i ∈ eachindex(covering)
        @threads for j ∈ eachindex(covering)

            i < j && continue

            if predicate(X, covering[i], covering[j])
                adj_matrix[i, j] = 1            
                adj_matrix[j, i] = 1
            end
        end
    end
    return adj_matrix
end
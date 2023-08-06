"""
Calculate the centroid of each subset of a covered space
"""
function centroid(CX::CoveredPointCloud)
    ctds = map(CX.covering) do ids
        map(mean, eachrow(CX.X[:, ids]))
    end |> stack

    return ctds
end

"""
Create the adjacent matrix from a covering
"""
function nerve_1d(CX::CoveredPointCloud)
    n = CX.covering |> length
    g = Graph(n)
    
    cv = CX.covering
    for i ∈ 1:n
        for j ∈ i:n
            i == j && continue
            if !isdisjoint(cv[i], cv[j])
                add_edge!(g, i, j)
            end
        end
    end

    return g
end
# excentricity
transpose_matrix(X::PointCloud) = permutedims(X, [2, 1])

function excentricity(p::Vector{<:Real}, X::PointCloud; distance = Euclidean(), transposed = true)
    Xᵗ = if transposed == true
        X
    else 
        transpose_matrix(X)
    end

    n_points = size(Xᵗ)[2]

    s = sum(colwise(distance, p, Xᵗ)) / n_points                    

    return s
end

function excentricity(X::PointCloud; distance = Euclidean(), transposed = false)
    Xᵗ = if transposed == true
        X
    else 
       transpose_matrix(X)
    end
    
    n_points = size(Xᵗ)[2]
    
    s = zeros(Float32, n_points)
    
    n_points == 0 && return(s)

    @threads for i ∈ 1:n_points 
        p = Xᵗ[:, i]       
        s[i] = excentricity(p, Xᵗ; distance = distance)
    end

    return s
end
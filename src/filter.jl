"""
    excentricity(p::Vector{<:Real}, X::PointCloud; metric = Euclidean())

Calculate the distance of p to every other point of X using the metric `metric`
"""
function excentricity(p::Vector{<:Real}, X::PointCloud; metric = Euclidean())
    Xᵗ = transpose_matrix(X)

    n_points = size(Xᵗ)[2]

    s = sum(colwise(metric, p, Xᵗ)) / n_points                    

    return s
end

function excentricity(X::PointCloud; metric = Euclidean())
    Xᵗ = transpose_matrix(X)    
    
    n_points = size(Xᵗ)[2]
    
    s = zeros(Float32, n_points)
    
    n_points == 0 && return(s)

    @threads for i ∈ 1:n_points 
        p = Xᵗ[:, i]       
        s[i] = excentricity(p, Xᵗ; metric = metric)
    end

    return s
end

export excentricity

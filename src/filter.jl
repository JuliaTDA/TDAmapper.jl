"""
    excentricity(
        p::Vector{<:Real}, X::PointCloud; 
        metric = Euclidean()
        )

Calculate the distance of p to every other point of X using 
the metric `metric`.
"""
function excentricity(p::Vector{<:Real}, X::PointCloud; metric::SemiMetric = Euclidean())
    n_points = size(X)[2]

    s = sum(colwise(metric, p, X)) / n_points                    

    return s
end

"""
    excentricity(X::PointCloud; metric = Euclidean())

Calculate the distance of every point p ∈ X to every other point of X using the metric `metric`
"""
function excentricity(X::PointCloud; metric::SemiMetric = Euclidean())
    n_points = size(X)[2]
    
    s = zeros(Float32, n_points)
    
    n_points == 0 && return(s)

    @threads for i ∈ 1:n_points 
        p = X[:, i]       
        s[i] = excentricity(p, X; metric = metric)
    end

    return s
end

# function umap(X::PointCloud) 
#     umap(X)
# end
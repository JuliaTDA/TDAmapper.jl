"""
mapper(
    X::PointCloud
    ,filter_values::Vector{<:Real}
    ,covering_intervals::Vector{<:Interval}
    ;clustering = cluster_dbscan
    )

Create the mapper graph of a given pointcloud `X`,
with a vector of `filter_values`, using the
`covering_intervals` and a `clustering` function.

# Examples

etc.
"""
function mapper(
    X::PointCloud
    ,filter_values::Vector{<:Real}
    ,covering_intervals::Vector{<:Interval}
    ;clustering = cluster_dbscan
    )
 
    # calculate the pullback
    first_covering = pre_image_covering(filter_values, covering_intervals)
    
    # cluster each pre-image
    covering = split_covering(CoveredPointCloud(X, first_covering), clustering = clustering)

    CX = CoveredPointCloud(X, covering)

    g = nerve_1d(CX)

    mapper = Mapper(CX = CX, graph = g)
    return mapper
end
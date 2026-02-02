"""
    create_outlier_cluster(x)

Replaces all occurrences of `0` in the input array `x` with a value one greater than the current maximum of `x`.
If there are no zeros in `x`, the array is returned unchanged.

# Arguments
- `x`: An array of numeric values.

# Returns
- An array where all zeros have been replaced by `maximum(x) + 1`, or the original array if no zeros are present.
"""
function create_outlier_cluster(x)
    if any(==(0), x)
        x = replace(x, 0 => maximum(x) + 1)
    end

    x
end

@testitem "create_outlier_cluster" begin
    using TDAmapper.Refiners

    x = [1, 2, 3]
    @test create_outlier_cluster(x) == x

    x[end] = 0
    @test create_outlier_cluster(x) == [1, 2, 3]

    x = [1, 1, 0]
    @test create_outlier_cluster(x) == [1, 1, 2]

    x = [0, 0, 0]
    @test create_outlier_cluster(x) == [1, 1, 1]
end

"""
    refine_cover(X::MetricSpace, C::Covering, R) -> Vector{Vector{Int}}

Refines a given cover `C` of a metric space `X` using the specified refiner `R`. 

# Arguments
- `X::MetricSpace`: The metric space containing the data points
- `C::Covering`: The initial cover, represented as a collection of index sets  
- `R`: The refiner or clustering method to apply to each subset

# Returns
- `Vector{Vector{Int}}`: A refined cover as a vector of integer index sets, 
  with outliers handled appropriately

# Description
For each subset of indices in the cover, the function applies the refiner to 
partition the subset into clusters. The process works as follows:

1. For each cover element `ids` in `C`:
   - Extract the subset `X[ids]` 
   - Apply the refiner `R(X[ids])` to get cluster assignments
   - Map cluster assignments back to original indices
2. Flatten all clusters into a single vector of index sets
3. Handle outliers (points assigned to cluster 0) by creating a separate outlier cluster

Any outliers (typically marked with 0 by some clustering methods) are reassigned 
to a separate outlier cluster using `create_outlier_cluster`.

# Examples
```julia
using TDAmapper
using TDAmapper.Refiners

X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0], [1.5, 2.5]])
C = [[1, 2, 4], [2, 3, 4]]  # Initial covering
R = DBscan(radius=0.5)      # DBSCAN refiner

refined_cover = refine_cover(X, C, R)
# Returns clustered index sets based on the clustering results
```

# See Also
- [`create_outlier_cluster`](@ref): Handles outlier reassignment
- [`AbstractRefiner`](@ref): Interface for refiner implementations
"""
function refine_cover(X::MetricSpace, C::Covering, R)
    # Preallocate result vector
    result = Vector{Vector{Int}}()

    for ids in C
        isempty(ids) && continue

        # Get cluster assignments for points in this cover element
        cluster_ids = R(X[ids])

        # Get unique cluster IDs (no need to sort - unique preserves first occurrence order)
        unique_clusters = unique(cluster_ids)

        # Map each cluster back to original indices
        for cl_id in unique_clusters
            cluster_indices = ids[findall(==(cl_id), cluster_ids)]
            push!(result, cluster_indices)
        end
    end

    # Handle outliers (cluster 0 in some methods)
    create_outlier_cluster(result)
end
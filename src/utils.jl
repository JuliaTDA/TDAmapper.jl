using ..TDAmapper

"""
    unique_sort(x)

The same as the composition unique ∘ sort.
"""
unique_sort = unique ∘ sort

"""
    transpose_matrix(X::PointCloud)

Transpose a point cloud.
"""
transpose_matrix(X::PointCloud) = permutedims(X, [2, 1])

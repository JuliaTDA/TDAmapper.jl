"""
    pre_image_id

For each point x of `fv`, find the indexes i of interval_covering
such that x ∈ interval_covering[i]
"""
function pre_image_covering(
    fv::Vector{<:Real}, interval_covering::Vector{<: Interval}
    )
    [findall(x -> x ∈ c, fv) for c ∈ interval_covering]
end
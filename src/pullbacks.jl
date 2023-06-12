function pre_image_id(fv::Vector{<:Real}, interval_covering::Vector{<: Interval})
    [findall(x -> x ∈ c, fv) for c ∈ interval_covering]
end
function layout_generic(CX::CoveredPointCloud, f::Function)
    ctd = centroid(CX)
    M = f(ctd)
    dim = M[:, 1] |> length
    @assert dim ∈ [2, 3] "dim must be 2 or 3!"
    pos = [Point{dim}(x) for x ∈ eachcol(M)]

    return pos
end

"""
    mds_layout(CX::CoveredPointCloud, dim::Integer = 2)

Create the MDS layout of a covered space using the centroid of each element of the covering
"""
function layout_mds(CX::CoveredPointCloud; dim::Integer = 2, kwargs...)
    f = x -> predict(fit(MDS, x, distances = false, maxoutdim = dim, kwargs...))
    pos = layout_generic(CX, f)

    return pos
end

function layout_lle(CX::CoveredPointCloud; dim::Integer = 2, kwargs...)
    f = x -> predict(fit(LLE, x, maxoutdim = dim, kwargs...))
    pos = layout_generic(CX, f)

    return pos
end

function layout_hlle(CX::CoveredPointCloud; dim::Integer = 2, kwargs...)
    f = x -> predict(fit(HLLE, x, maxoutdim = dim, kwargs...))
    pos = layout_generic(CX, f)

    return pos
end

function layout_lem(CX::CoveredPointCloud; dim::Integer = 2, kwargs...)
    f = x -> predict(fit(LEM, x, maxoutdim = dim, kwargs...))
    pos = layout_generic(CX, f)

    return pos
end

function layout_ltsa(CX::CoveredPointCloud; dim::Integer = 2, kwargs...)
    f = x -> predict(fit(LTSA, x, maxoutdim = dim, kwargs...))
    pos = layout_generic(CX, f)

    return pos
end

function layout_diffmap(CX::CoveredPointCloud; dim::Integer = 2, kwargs...)
    f = x -> predict(fit(DiffMap, x, maxoutdim = dim, kwargs...))
    pos = layout_generic(CX, f)

    return pos
end

function layout_tsne(CX::CoveredPointCloud; dim::Integer = 2, kwargs...)
    f = x -> predict(fit(TSNE, x, maxoutdim = dim, kwargs...))
    pos = layout_generic(CX, f)

    return pos
end

function layout_isomap(CX::CoveredPointCloud; dim::Integer = 2, kwargs...)
    f = x -> predict(fit(Isomap, x, maxoutdim = dim, kwargs...))
    pos = layout_generic(CX, f)

    return pos
end

"""
Calculate the centroid of each subset of a covered space
"""
function centroid(CX::CoveredPointCloud)
    ctds = map(CX.covering) do ids
        map(mean, eachrow(CX.X[:, ids]))
    end |> stack

    return ctds
end

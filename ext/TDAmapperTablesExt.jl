"""
    TDAmapperTablesExt

Package extension that connects TDAmapper to the
[Tables.jl](https://github.com/JuliaData/Tables.jl) ecosystem.

It provides methods for the [`euclidean_space`](@ref) and
[`node_statistics`](@ref) function stubs declared in TDAmapper proper. The
extension loads automatically whenever Tables.jl is available in the active
environment (e.g. after `using Tables` or `using DataFrames`).
"""
module TDAmapperTablesExt

using TDAmapper
using TDAmapper: AbstractMapper, euclidean_space, node_statistics
using Tables
import StatsBase

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

"""
    _is_real_eltype(T) -> Bool

Whether a column whose element type is `T` should be treated as a numeric
coordinate. Columns whose eltype is a plain `Real` qualify; columns that may
contain `missing` (eltype `Union{Missing, <:Real}`) do not, so that they are
excluded from automatic selection.
"""
_is_real_eltype(::Type{T}) where {T} = T <: Real

"""
    _has_missing_eltype(T) -> Bool

Whether a column eltype `T` admits `missing` while otherwise being numeric,
i.e. `T === Union{Missing, S}` with `S <: Real`. Such columns are excluded from
the default selection and rejected when requested explicitly.
"""
function _has_missing_eltype(::Type{T}) where {T}
    Missing <: T || return false
    S = Base.nonmissingtype(T)
    return S !== T && S <: Real
end

"""
    _numeric_columns(cols_obj, names) -> Vector{Symbol}

Return the names of the columns in `cols_obj` (a `Tables.columns` result) that
are purely numeric (eltype `<: Real`, no `missing`), preserving the order given
by `names`.
"""
function _numeric_columns(cols_obj, names)
    selected = Symbol[]
    for name in names
        col = Tables.getcolumn(cols_obj, name)
        if _is_real_eltype(eltype(col))
            push!(selected, name)
        end
    end
    return selected
end

# ---------------------------------------------------------------------------
# euclidean_space
# ---------------------------------------------------------------------------

"""
    euclidean_space(table; cols=nothing, standardize=false) -> EuclideanSpace

Build an `EuclideanSpace` from a Tables.jl-compatible `table`, one point per row.

See the docstring of the [`euclidean_space`](@ref) stub in TDAmapper for the
full description of the keyword arguments and behaviour.
"""
function TDAmapper.euclidean_space(table; cols=nothing, standardize::Bool=false)
    cols_obj = Tables.columns(table)
    all_names = collect(Tables.columnnames(cols_obj))

    if cols === nothing
        selected = _numeric_columns(cols_obj, all_names)
        if isempty(selected)
            throw(ArgumentError(
                "no numeric columns found to build a EuclideanSpace; " *
                "pass `cols` explicitly to select columns."))
        end
    else
        selected = collect(Symbol.(cols))
        for name in selected
            if !(name in all_names)
                throw(ArgumentError("column $(name) not found in the table."))
            end
            col = Tables.getcolumn(cols_obj, name)
            T = eltype(col)
            if _has_missing_eltype(T)
                throw(ArgumentError(
                    "column $(name) has element type $(T) and may contain " *
                    "missing values, which cannot be used to build a " *
                    "EuclideanSpace. Drop or impute the missing values first."))
            end
            if !_is_real_eltype(T)
                throw(ArgumentError(
                    "column $(name) has non-numeric element type $(T); " *
                    "only columns with eltype <: Real can become coordinates."))
            end
        end
    end

    # Materialize selected columns as Float64 vectors.
    columns = [Float64.(Tables.getcolumn(cols_obj, name)) for name in selected]

    if standardize
        for (j, col) in enumerate(columns)
            μ = StatsBase.mean(col)
            σ = StatsBase.std(col)
            if σ ≈ 0
                columns[j] = col .- μ
            else
                columns[j] = (col .- μ) ./ σ
            end
        end
    end

    nrows = isempty(columns) ? 0 : length(columns[1])
    # Each row becomes a point.
    points = [Float64[col[i] for col in columns] for i in 1:nrows]

    return EuclideanSpace(points)
end

# ---------------------------------------------------------------------------
# node_statistics
# ---------------------------------------------------------------------------

"""
    node_statistics(M::AbstractMapper, table; stats=(mean,)) -> NamedTuple

Summarise the numeric columns of a Tables.jl-compatible `table` over the nodes
of a mapper `M`, producing one row per node.

See the docstring of the [`node_statistics`](@ref) stub in TDAmapper for the
full description of the output columns and behaviour.
"""
function TDAmapper.node_statistics(M::AbstractMapper, table; stats=(StatsBase.mean,))
    cols_obj = Tables.columns(table)
    all_names = collect(Tables.columnnames(cols_obj))

    nrows = Tables.rowcount(cols_obj)
    npoints = length(M.X)
    if nrows != npoints
        throw(ArgumentError(
            "table has $(nrows) rows but the mapper's metric space has " *
            "$(npoints) points; they must match (one row per point)."))
    end

    numeric_names = _numeric_columns(cols_obj, all_names)
    numeric_cols = Dict(name => Float64.(Tables.getcolumn(cols_obj, name)) for name in numeric_names)

    C = M.C
    nnodes = length(C)

    # Base columns.
    result = Pair{Symbol, Vector}[]
    push!(result, :node => collect(1:nnodes))
    push!(result, :size => [length(c) for c in C])

    for name in numeric_names
        col = numeric_cols[name]

        # Per-node statistics for each requested function.
        for f in stats
            colname = Symbol("$(name)_$(nameof(f))")
            values = Vector{Float64}(undef, nnodes)
            for (k, idxs) in enumerate(C)
                values[k] = Float64(f(@view col[idxs]))
            end
            push!(result, colname => values)
        end

        # Per-node z-score of the mean against the global distribution.
        global_mean = StatsBase.mean(col)
        global_std = StatsBase.std(col)
        zcolname = Symbol("$(name)_z")
        zvalues = Vector{Float64}(undef, nnodes)
        for (k, idxs) in enumerate(C)
            node_mean = StatsBase.mean(@view col[idxs])
            zvalues[k] = global_std ≈ 0 ? 0.0 : (node_mean - global_mean) / global_std
        end
        push!(result, zcolname => zvalues)
    end

    return NamedTuple(result)
end

end # module

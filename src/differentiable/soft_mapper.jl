using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: Trivial
using TDAmapper.Nerves: SimpleNerve

"""
    SoftMapper{S<:MetricSpace, G}

Result of [`soft_mapper`](@ref). Wraps the metric space `X`, per-node point
index sets `C`, the nerve graph `g`, the node filtration values `v`
(`mean` of the filter over each node), the soft membership matrix `Q`
(n points × r intervals), and the filter values `f_X` at the given `θ`.

`Q` is stored for inspection and as the bridge to the Monte-Carlo (faithful)
version; it does **not** enter the v1 gradient.
"""
@kwdef struct SoftMapper{S<:MetricSpace, G}
    X::S
    C::Covering
    g::G
    v::Vector{Float64}
    Q::Matrix{Float64}
    f_X::Vector{Float64}
end

import Graphs
function Base.show(io::IO, sm::SoftMapper)
    print(io, "SoftMapper with $(Graphs.nv(sm.g)) nodes and $(Graphs.ne(sm.g)) edges")
end

"""
    node_filtration(members, f_X) -> Vector

Node filtration value of each mapper node: the `mean` of the filter values
`f_X` over the node's member point indices. Differentiable in `f_X`.
"""
node_filtration(members, f_X) = [mean(f_X[m]) for m in members]

"""
    soft_mapper(X, θ; filter=LinearFilter(), cover=Uniform(), refiner=Trivial(),
                nerve=SimpleNerve(), sharpness=10.0) -> SoftMapper

Build a Mapper at filter parameters `θ` together with its differentiable node
filtration and soft membership. The graph combinatorics use the existing hard
`R1Cover` (`f_X[i] ∈ interval`); node values are `mean(f_X)` over each node.
"""
function soft_mapper(X::MetricSpace, θ::AbstractVector;
        filter = LinearFilter(), cover = Uniform(), refiner = Trivial(),
        nerve = SimpleNerve(), sharpness::Real = 10.0)
    f_X = collect(float.(filter(X, θ)))
    cov = R1Cover(f_X, cover)
    M = mapper(X, cov, refiner, nerve)
    members = M.C
    v = Float64.(node_filtration(members, f_X))
    Q = soft_membership(f_X, cov.U; sharpness = sharpness)
    return SoftMapper(X = X, C = members, g = M.g, v = v, Q = Q, f_X = f_X)
end

"""
    optimize_filter(X, θ₀; kwargs...)

Gradient-tune the Mapper filter parameters. **Stub** — the method is provided
by the `TDAmapperZygoteExt` package extension, which loads once both `Zygote`
and `Optimisers` are present (`using Zygote, Optimisers`).
"""
function optimize_filter end

@testitem "soft_mapper builds a SoftMapper with node values" begin
    using TDAmapper
    using TDAmapper.IntervalCovers: Uniform
    using TDAmapper.Refiners: Trivial
    using TDAmapper.Nerves: SimpleNerve
    using Graphs

    pts = [[Float64(i), 0.0] for i in 0:9]
    X = EuclideanSpace(pts)

    sm = soft_mapper(X, [1.0, 0.0];
                     cover = Uniform(length = 4, expansion = 0.3),
                     refiner = Trivial(), nerve = SimpleNerve())

    @test sm isa SoftMapper
    @test length(sm.v) == length(sm.C)
    @test Graphs.nv(sm.g) == length(sm.C)
    @test size(sm.Q, 1) == length(X)
    @test all(isfinite, sm.v)
end

@testitem "node_filtration averages the filter over each node" begin
    using TDAmapper
    members = [[1, 2], [3]]
    f_X = [10.0, 20.0, 5.0]
    @test node_filtration(members, f_X) == [15.0, 5.0]
end

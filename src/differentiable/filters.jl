"""
    LinearFilter()

Parameterized linear filter `f_θ(x) = ⟨x, θ⟩` (the paper's linear filter).
Callable as `LinearFilter()(X, θ)`, returning the vector `[⟨xᵢ, θ⟩]`,
differentiable in `θ`. Any callable `(X, θ) -> Vector{<:Real}` may be used in
its place; only `LinearFilter` ships in v1.
"""
struct LinearFilter end

function (::LinearFilter)(X, θ::AbstractVector)
    P = ChainRulesCore.@ignore_derivatives reduce(hcat, collect(X))  # d × n, θ-independent
    return vec(transpose(θ) * P)
end

@testitem "LinearFilter values and gradient" begin
    using TDAmapper
    using Zygote

    X = EuclideanSpace([[1.0, 0.0], [0.0, 1.0], [1.0, 1.0]])
    f = LinearFilter()

    @test f(X, [1.0, 0.0]) ≈ [1.0, 0.0, 1.0]
    @test f(X, [0.0, 1.0]) ≈ [0.0, 1.0, 1.0]

    g = Zygote.gradient(θ -> sum(f(X, θ)), [1.0, 1.0])[1]
    @test g ≈ [2.0, 2.0]
end

_sigmoid(z) = 1 / (1 + exp(-z))

"""
    soft_membership(f_X, U; sharpness=10.0) -> Matrix

Smooth (differentiable) cover membership. Returns `Q ∈ [0,1]^{n×r}` where
`Q[i,j] = σ(sharpness·(f_X[i]-aⱼ))·σ(sharpness·(bⱼ-f_X[i]))` is a smooth bump
approximating the indicator of `f_X[i] ∈ Uⱼ = [aⱼ, bⱼ]`. As `sharpness → ∞`,
`Q` converges to TDAmapper's hard membership (`f_X[i] ∈ Uⱼ`) at interior
points. Generalizes `ImageCovers.R1Cover` membership.
"""
function soft_membership(f_X::AbstractVector{<:Real}, U::AbstractVector{<:Interval}; sharpness::Real = 10.0)
    n = length(f_X)
    r = length(U)
    Q = Matrix{Float64}(undef, n, r)
    for j in 1:r
        a = U[j].a
        b = U[j].b
        for i in 1:n
            t = f_X[i]
            Q[i, j] = _sigmoid(sharpness * (t - a)) * _sigmoid(sharpness * (b - t))
        end
    end
    return Q
end

@testitem "soft_membership → hard membership as sharpness grows" begin
    using TDAmapper

    f_X = [0.3, 0.8, 1.5]
    U = [Interval(0.0, 0.6), Interval(0.4, 1.0)]

    Q = soft_membership(f_X, U; sharpness = 1000.0)
    hard = [1.0 0.0; 0.0 1.0; 0.0 0.0]

    @test size(Q) == (3, 2)
    @test all(0.0 .<= Q .<= 1.0)
    @test Q ≈ hard atol = 1e-3
end

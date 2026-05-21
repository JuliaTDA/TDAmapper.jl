using BenchmarkTools
using TDAmapper
using TDAmapper.ImageCovers, TDAmapper.IntervalCovers
using TDAmapper.DomainCovers, TDAmapper.Refiners, TDAmapper.Nerves

# ── Dataset generators ────────────────────────────────────────────────────────

function noisy_circle(n::Int; noise=0.05)
    θ = range(0, 2π, length=n+1)[1:end-1]
    pts = [[cos(t) + noise*randn(), sin(t) + noise*randn()] for t in θ]
    EuclideanSpace(pts)
end

function noisy_torus(n::Int; R=2.0, r=1.0, noise=0.05)
    pts = Vector{Vector{Float64}}(undef, n)
    for i in 1:n
        θ = 2π * rand()
        φ = 2π * rand()
        x = (R + r*cos(φ)) * cos(θ) + noise*randn()
        y = (R + r*cos(φ)) * sin(θ) + noise*randn()
        z = r * sin(φ) + noise*randn()
        pts[i] = [x, y, z]
    end
    EuclideanSpace(pts)
end

# ── Benchmark suite ───────────────────────────────────────────────────────────

const SUITE = BenchmarkGroup()

for (name, n) in [("small", 100), ("medium", 10_000), ("large", 100_000)]
    SUITE[name] = BenchmarkGroup()

    X_circle = noisy_circle(n)
    f_circle = first.(X_circle)

    # classical mapper: Uniform + DBscan
    SUITE[name]["classical_uniform_dbscan"] = @benchmarkable classical_mapper(
        $X_circle,
        R1Cover($f_circle, Uniform(length=10, expansion=0.3)),
        DBscan(radius=0.3),
        SimpleNerve()
    )

    # classical mapper: QuantileCover + KMeans
    SUITE[name]["classical_quantile_kmeans"] = @benchmarkable classical_mapper(
        $X_circle,
        R1Cover($f_circle, QuantileCover(n_intervals=10, expansion=0.3)),
        KMeans(k=2),
        SimpleNerve()
    )

    # ball mapper: EpsilonBall + Trivial
    landmarks = collect(1:min(20, n))
    SUITE[name]["ball_mapper"] = @benchmarkable ball_mapper(
        $X_circle,
        $landmarks,
        0.3
    )
end

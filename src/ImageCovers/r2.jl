"""
    R2Cover{C1<:AbstractIntervalCover, C2<:AbstractIntervalCover} <: AbstractImageCover

A 2D pullback cover for filter functions f: X → ℝ².

Constructs a grid covering by taking the Cartesian product of two interval covers.
Each grid cell is the intersection of one interval from cover1 and one from cover2.

# Fields
- `f_X::Vector{Tuple{Float64,Float64}}`: Filter values as (f₁, f₂) pairs
- `cover1::C1`: Interval cover along the first filter axis
- `cover2::C2`: Interval cover along the second filter axis

# Examples
```julia
using TDAmapper
using TDAmapper.ImageCovers, TDAmapper.IntervalCovers

X = sphere(100, dim=3)
f = [(p[1], p[2]) for p in X]  # Use first two coordinates as filters
C = R2Cover(f, Uniform(length=5, expansion=0.3), Uniform(length=5, expansion=0.3))
cover = make_cover(C)  # Returns vector of index vectors
```
"""
@kwdef struct R2Cover{C1<:AbstractIntervalCover, C2<:AbstractIntervalCover} <: AbstractImageCover
    f_X::Vector{Tuple{Float64,Float64}}
    cover1::C1
    cover2::C2
end

# Constructor that accepts any 2-tuple element type
function R2Cover(f_X::Vector{<:Tuple{<:Real,<:Real}}, c1::AbstractIntervalCover, c2::AbstractIntervalCover)
    f_converted = [(Float64(a), Float64(b)) for (a, b) in f_X]
    R2Cover(f_X=f_converted, cover1=c1, cover2=c2)
end

"""
    TDAmapper.make_cover(c::R2Cover) -> Vector{Vector{Int}}

Generate the 2D pullback covering from an R2Cover.

For each pair of intervals (I1, I2) from the Cartesian product of the two interval
covers, finds all indices i such that f_X[i][1] ∈ I1 and f_X[i][2] ∈ I2.
Empty cells are omitted.
"""
function TDAmapper.make_cover(c::R2Cover)
    f1 = [t[1] for t in c.f_X]
    f2 = [t[2] for t in c.f_X]
    intervals1 = c.cover1(f1)
    intervals2 = c.cover2(f2)

    cover = Vector{Vector{Int}}()
    for I1 in intervals1
        for I2 in intervals2
            cell = [i for i in eachindex(c.f_X) if c.f_X[i][1] ∈ I1 && c.f_X[i][2] ∈ I2]
            isempty(cell) || push!(cover, cell)
        end
    end
    cover
end

function TDAmapper.validate(c::R2Cover)
    isempty(c.f_X) && throw(MapperArgumentError("R2Cover — f_X must not be empty"))
    return nothing
end

@testitem "R2Cover" begin
    using TDAmapper
    using TDAmapper.ImageCovers, TDAmapper.IntervalCovers

    # Simple 2D grid test
    f = [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]
    C = R2Cover(f, Uniform(length=2, expansion=0.1), Uniform(length=2, expansion=0.1))
    cover = make_cover(C)
    @test !isempty(cover)
    @test all(v -> !isempty(v), cover)
    # Each point should appear in at least one cell
    all_indices = vcat(cover...)
    @test all(i -> i ∈ all_indices, 1:4)
end

using BenchmarkTools, TDAmapper, Zygote, Optimisers, Random, LinearAlgebra, Graphs, Test
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: Trivial
using TDAmapper.Nerves: SimpleNerve
BLAS.set_num_threads(1)

function benchmark_differentiable(;seed=20261003,samples=20,seconds=1.0,
        output=joinpath(@__DIR__,"differentiable_baseline.csv"))
    rng = Xoshiro(seed)
    root = dirname(@__DIR__)
    open(output*".metadata","w") do io
        println(io,"cpu = ",Sys.CPU_NAME,"\nos = ",Sys.KERNEL,"\narch = ",Sys.ARCH)
        println(io,"git_revision = ",strip(read(`git -C $root rev-parse HEAD`,String)))
        println(io,"working_tree_dirty = ",!isempty(read(`git -C $root status --porcelain`,String)))
        println(io,"benchmarktools = ",pkgversion(BenchmarkTools),"\nzygote = ",pkgversion(Zygote))
        println(io,"optimisers = ",pkgversion(Optimisers))
    end
    rows = NamedTuple[]
    for n in (100,300,1000)
        angles = collect(range(0,2π;length=n+1))[1:n]
        X = EuclideanSpace([[cos(t)+0.005randn(rng),sin(t)+0.005randn(rng)] for t in angles])
        θ = [0.9,0.2]
        cover = Uniform(length=10,expansion=0.3)
        build = () -> soft_mapper(X,θ;cover=cover,refiner=Trivial(),nerve=SimpleNerve())
        sm = build()
        nonempty = findall(!isempty,sm.C)
        members = sm.C[nonempty]
        graph = first(Graphs.induced_subgraph(sm.g,nonempty))
        filter = LinearFilter()
        loss = t -> total_extended_persistence(graph,node_filtration(members,filter(X,t)))
        gradient = t -> Zygote.gradient(loss,t)[1]
        g = gradient(θ)
        @test g!==nothing && all(isfinite,g)
        numerical = [(loss(θ+1e-6*[i==j for i in eachindex(θ)])-
            loss(θ-1e-6*[i==j for i in eachindex(θ)]))/2e-6 for j in eachindex(θ)]
        @test g ≈ numerical atol=1e-6 rtol=1e-5
        optimize = () -> optimize_filter(X,θ;cover=cover,refiner=Trivial(),
            nerve=SimpleNerve(),n_epochs=3)
        for (name,operation) in (("build",build),("fixed_graph_gradient",()->gradient(θ)),
                ("optimize_3_epochs",optimize))
            result = operation() # exclude compilation
            trial = run(@benchmarkable($operation());samples=samples,seconds=seconds,evals=1)
            estimate = median(trial)
            push!(rows,(operation=name,n_points=n,n_nodes=nv(graph),n_edges=ne(graph),
                nanoseconds=estimate.time,bytes=estimate.memory,allocations=estimate.allocs,
                actual_samples=length(trial),seed=seed,julia=string(VERSION),
                threads=Threads.nthreads(),blas_threads=BLAS.get_num_threads(),
                package_version=string(pkgversion(TDAmapper))))
        end
    end
    open(output,"w") do io
        println(io,join(string.(keys(first(rows))),','))
        for row in rows
            println(io,join(string.(values(row)),','))
        end
    end
    println("Wrote ",length(rows)," differentiable Mapper cases to ",output)
    return rows
end

if abspath(PROGRAM_FILE)==@__FILE__
    benchmark_differentiable(;output=isempty(ARGS) ? joinpath(@__DIR__,"differentiable_baseline.csv") : ARGS[1])
end

using Random
using Zygote
using Optimisers
using Flux, Lux

@testset "Explicit MLP parameters and nonlinear optimization" begin
    X=EuclideanSpace([[-1.,-1.],[-1.,1.],[1.,-1.],[1.,1.],[0.,0.],[.5,.5]])
    f=MLPFilter([2,8,1])
    p=initial_parameters(f;rng=Random.Xoshiro(12))
    @test p==initial_parameters(f;rng=Random.Xoshiro(12))
    @test length(f(X,p))==length(X)
    grad=Zygote.gradient(q -> sum(abs2,f(X,q)),p)[1]
    @test all(isfinite,grad.layers[1].weight)
    target=[sum(abs2,x) for x in X]
    objective=q -> sum(abs2,f(X,q).-target)/length(X)
    before=objective(p)
    result=optimize_filter(X,p;filter=f,loss=(g,v)->0.0*sum(v),regularizer=objective,
        optimizer=Optimisers.Adam(.025),n_epochs=150)
    @test objective(result.θ)<before/10
    @test p==initial_parameters(f;rng=Random.Xoshiro(12)) # caller's tree unchanged
    @test length(result.history)==150
    @test all(isfinite,result.history) # sparse data leave some cover intervals empty
    @test_throws ArgumentError optimize_filter(X,p;filter=f,n_epochs=0)
    @test_throws ArgumentError MLPFilter([2,3,2])
    @test_throws ArgumentError optimize_filter(X,[1.,1.];filter=(X,p)->fill(NaN,length(X)),n_epochs=1)
end

@testset "Flux and Lux explicit adapters" begin
    X=EuclideanSpace([[0.,1.],[1.,0.],[1.,1.]])
    fm=Flux.Chain(Flux.Dense(2=>4,tanh),Flux.Dense(4=>1))
    F=flux_filter(fm)
    @test length(F.filter(X,F.parameters))==3
    @test all(isfinite,Zygote.gradient(p -> sum(F.filter(X,p)),F.parameters)[1])
    @test_throws ArgumentError flux_filter(Flux.Dropout(.2))
    lm=Lux.Chain(Lux.Dense(2=>4,tanh),Lux.Dense(4=>1))
    L=lux_filter(lm;rng=Random.Xoshiro(31))
    @test L.parameters==lux_filter(lm;rng=Random.Xoshiro(31)).parameters
    @test length(L.filter(X,L.parameters))==3
    @test Zygote.gradient(p -> sum(L.filter(X,p)),L.parameters)[1]!==nothing
end

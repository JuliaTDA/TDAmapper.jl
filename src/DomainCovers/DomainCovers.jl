module DomainCovers

using ..TDAmapper
abstract type AbstractDomainCover <: AbstractCover end

include("epsilon_ball.jl")
export EpsilonBall,
    epsilon_ball

end # module
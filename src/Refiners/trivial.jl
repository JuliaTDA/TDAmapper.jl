struct Trivial <: AbstractRefiner

end

function (t::Trivial)(X::MetricSpace)
    fill(1, length(X))
end
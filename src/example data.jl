module Datasets

function circle(n::Integer = 100; radius::Number = 1, sd::Number = 0)
    p = rand(n)*2*π
    [sin.(p) cos.(p)]
end

end # module
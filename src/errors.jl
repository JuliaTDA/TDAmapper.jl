"""
    MapperArgumentError(msg)

Thrown when a mapper component is constructed or called with an invalid argument.
The message names the struct and parameter, e.g.:
    "DBscan — radius must be > 0, got -0.5"
"""
struct MapperArgumentError <: Exception
    msg::String
end

"""
    MapperDomainError(msg)

Thrown when a mapper computation encounters a domain violation at runtime,
e.g. a filter value outside the expected range or an empty cover element.
"""
struct MapperDomainError <: Exception
    msg::String
end

Base.showerror(io::IO, e::MapperArgumentError) = print(io, "MapperArgumentError: ", e.msg)
Base.showerror(io::IO, e::MapperDomainError) = print(io, "MapperDomainError: ", e.msg)

"""
    validate(x, args...)

Validate a mapper component before the pipeline runs. The default method is a no-op;
concrete cover, refiner, and nerve types override it to enforce their parameter contracts.
Throws `MapperArgumentError` or `MapperDomainError` on failure.
"""
validate(x, _...) = nothing

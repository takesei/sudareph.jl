abstract type BaseParams end
abstract type BaseVar{T} end
abstract type ArrayVar{T} <: BaseVar{T} end

struct Const{T} <: BaseVar{T}
    value::T
end
mutable struct Status{T} <: BaseVar{T}
    value::T
end


struct ArrayConst{T} <: ArrayVar{T}
    value::Vector{T}
end
mutable struct ArrayStatus{T} <: ArrayVar{T}
    value::Vector{T}
end

Base.getindex(value::T, name::Symbol) where T <: BaseParams = getfield(value, name).value
Base.setindex!(x::T, val::Any, f::Symbol) where {T <: BaseParams} = setfield!(getfield(x, f), :value, val)

save(p::BaseParams) = error("Implement save for your Params")
Base.copy(p::BaseParams) = error("Implment copy for your Params")

Base.convert(::Type{T}, x::U) where {T<:BaseVar, U} = T(x)
Base.convert(::Type{T}, x::T) where {T<:BaseVar} = x

export BaseParams, BaseVar, Const, Status, save

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
    value::Array{T}
    ArrayConst(x::Array{T}) where T = new{T}(x)
end
mutable struct ArrayStatus{T} <: ArrayVar{T}
    value::Array{T}
    ArrayStatus(x::Array{T}) where T = new{T}(x)
end

Base.getindex(value::T, name::Symbol) where T <: BaseParams = getfield(value, name).value
Base.setindex!(x::T, val::Any, f::Symbol) where {T <: BaseParams} = setfield!(getfield(x, f), :value, val)

save(::BaseParams) = error("Implement save for your Params")
Base.copy(::BaseParams) = error("Implment copy for your Params")

Base.copy(::BaseVar) = error("Implment copy for your Variable")
Base.copy(p::Const) = Const(copy(p.value))
Base.copy(p::Status) = Status(copy(p.value))
Base.copy(p::Const{T}) where T<:AbstractString = Const(p.value)
Base.copy(p::Status{T}) where T<:AbstractString = Status(p.value)

Base.convert(::Type{T}, x::U) where {T<:BaseVar, U} = T(x)
Base.convert(::Type{T}, x::T) where {T<:BaseVar} = x

export BaseParams, BaseVar, Const, Status, save, ArrayConst, ArrayStatus, ArrayVar

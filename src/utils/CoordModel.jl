function padding(x::Matrix{U}) where U
    field = zeros(U, size(x) .+ 2)
    field[begin+1:end-1, begin+1:end-1] = x
    return field
end

function padding(x::Vector{U}) where U
    field = zeros(U, size(x) .+ 2)
    field[begin+1:end-1] = x
    return field
end

supress(x::Matrix{U}) where U = x[begin+1:end-1, begin+1:end-1]
supress(x::Vector{U}) where U = x[begin+1:end-1]

function periodicbc!(x::Matrix{T}) where T
    x[begin, :] = x[end-1, :]
    x[end, :] = x[begin+1, :]
    x[:, begin] = x[:, end-1]
    x[:, end] = x[:, begin+1]
    return x
end

function periodicbc!(x::Vector{T}) where T
    x[begin] = x[end-1]
    x[end] = x[begin+1]
    return x
end

mutable struct CoordStatus{T} <: BaseVar{T}
    value::Matrix{T}
    function CoordStatus(x::Matrix{U}; bc::Function = x -> x) where U 
        field = padding(x)
        field = bc(field)
        return new{U}(field)
    end
end

mutable struct ArrayCoordStatus{T} <: ArrayVar{T}
    value::Vector{Matrix{T}}
    function ArrayCoordStatus(x::Vector{Matrix{U}}; bc::Function = x->x) where U
        field = map(x) do s
            field = padding(s)
            field = bc(field)
            return field
        end
        return new{U}(field)
    end
end

Base.@kwdef struct CoordModel{T<:BaseParams} <: BaseModel{T}
    iter::Function
    params::T
    save_by::UInt64
    dt::Float64
    dx::Float64
    n_iter::UInt64
end

function laplacian(s::Matrix{T})::Matrix{T} where T
    @views return (
        s[begin+2:end, begin+1:end-1]
        + s[begin:end-2, begin+1:end-1]
        + s[begin+1:end-1, begin+2:end]
        + s[begin+1:end-1, begin:end-2]
        - 4 * s[begin+1:end-1, begin+1:end-1]
   )
end

function laplacian(s::Vector{T})::Vector{T} where T
    @views return (
        s[begin+2:end]
        + s[begin:end-2]
        - 2 * s[begin+1:end-1]
   )
end


Δ(s::Matrix{T}) where {T<:Real} = laplacian(s)
Δ(s::Vector{T}) where {T<:Real} = laplacian(s)

function start(mod::CoordModel; kwargs...)::Vector
    dt = haskey(kwargs, :dt) ? kwargs[:dt] : (mod.dt)
    dx = haskey(kwargs, :dx) ? kwargs[:dx] : (mod.dx)
    save_by = haskey(kwargs, :save_by) ? kwargs[:save_by] : (mod.save_by)
    n_iter = haskey(kwargs, :n_iter) ? kwargs[:n_iter] : (mod.n_iter)

    st = copy(mod.params)
    res = Vector{typeof(save(st))}(undef, div(n_iter, save_by)+1)
    res[begin] = save(st)

    @progress for i in 1:n_iter
        st = mod.iter(st, dt, dx)

        if i % save_by == 0
            res[begin+div(i, save_by)] = save(st)
        end
    end
    return res
end

export CoordModel,
       Δ,
       laplacian,
       start,
       CoordStatus,
       padding,
       periodicbc!,
       ArrayCoordStatus,
       supress

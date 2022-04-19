Base.@kwdef struct CoordModel{T<:BaseParams} <: BaseModel{T}
    iter::Function
    params::T
    save_by::UInt64
    dt::Float64
    dx::Float64
    n_iter::UInt64
end

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

function Base.copy(p::CoordStatus{T}) where T
    ret = CoordStatus(zeros(T, 0,0))
    ret.value = copy(p.value)
    return ret
end

function Base.copy(p::ArrayCoordStatus{T}) where T
    ret = ArrayCoordStatus([zeros(T, 0,0)])
    ret.value = copy(p.value)
    return ret
end


export CoordModel, start, CoordStatus, ArrayCoordStatus

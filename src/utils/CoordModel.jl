Base.@kwdef struct CoordModel{T<:BaseParams} <: BaseModel{T}
    iter::Function
    params::T
    save_by::UInt64
    dt::Float64
    dx::Float64
    n_iter::UInt64
end

function laplacian(s::Matrix{T})::Matrix{T} where {T<:Real}
    res = zeros(T, size(s))
    res[begin:end-1, :] += @view s[begin+1:end, :]
    res[begin+1:end, :] += @view s[begin:end-1, :]
    res[:, begin:end-1] += @view s[:, begin+1:end]
    res[:, begin+1:end] += @view s[:, begin:end-1]
    res -= 4 * s
    return res
end

Δ(s::Matrix{T}) where {T<:Real} = laplacian(s)

function start(mod::CoordModel; kwargs...)::Vector
    dt = haskey(kwargs, :dt) ? kwargs[:dt] : (mod.dt)
    dx = haskey(kwargs, :dx) ? kwargs[:dx] : (mod.dx)
    save_by = haskey(kwargs, :save_by) ? kwargs[:save_by] : (mod.save_by)
    n_iter = haskey(kwargs, :n_iter) ? kwargs[:n_iter] : (mod.n_iter)

    res = Vector(undef, div(n_iter, save_by)+1)

    st = copy(mod.params)
    res[begin] = save(st)

    @progress for i in 1:n_iter
        st = mod.iter(st, dt, dx)

        if i % save_by == 0
            res[begin+div(i, save_by)] = save(st)
        end
    end
    return res
end

export CoordModel, Δ, laplacian, start

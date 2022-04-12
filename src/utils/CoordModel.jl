Base.@kwdef struct CoordModel{T<:BaseParams} <: BaseModel
    update::Function
    params::T
    save_by::UInt64
    dt::Float64
    dx::Float64
    n_iter::UInt64
end

function Δ(s::Matrix{T})::Matrix{T} where {T<:Real}
    res = zeros(T, size(s))
    @. res[begin:end-1, :] += @view s[begin+1:end, :]
    @. res[begin+1:end, :] += @view s[begin:end-1, :]
    @. res[:, begin:end-1] += @view s[:, begin+1:end]
    @. res[:, begin+1:end] += @view s[:, begin:end-1]
    return res
end

# @NamedTuple{u::Matrix{Float64}, v::Matrix{Float64}}
function run(mod::CoordModel; kwargs...) where {T}
    dt = (mod.dt)
    dx = (mod.dx)
    save_by = (mod.save_by)
    n_iter = (mod.n_iter)

    res = Vector{T}(undef, div(n_iter, save_by))

    st = mod.params
    res[begin] = save(st)

    @progress for i in 1:n_iter
        st = mod.update(st, dt, dx)

        if i % save_by == 0
            res[begin+i] = save(st)
        end
    end
    return res
end

export CoordModel, Δ, run

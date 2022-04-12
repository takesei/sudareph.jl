Base.@kwdef struct BaseModel{T<:BaseParams}
    update::Function
    params::{T}
    save_by::UInt64
    n_iter::UInt64
end

function run(mod::BaseModel; kwargs...)::Vector{T} where {T}
    res = Vector{T}(undef, round(mod.n_iter / mod.save_by))
    st = mod.params

    res[begin] = save(st)

    @progress for i in 1:mod.n_iter
        st = mod.update(st)

        if i % mod.save_by == 0
            res[begin+i] = save(st)
        end
    end
    return res
end

export BaseModel, run

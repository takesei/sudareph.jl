abstract type BaseParams end

function update!(p::BaseParams; args...)
    for k in keys(args)
        setfield!(getfield(p, k), :value, args[k])
    end
end

function save(p::BaseParams)
    return p
end

struct Const{T}
    value::T
end

mutable struct Status{T}
    value::T
end

function update!(st::Status{T}, val::T) where {T}
    st.value = val
end

export BaseParams, update!, save, Const, Status, update!

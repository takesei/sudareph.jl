function padding(x::Array{U, N}) where {U, N}
    field = zeros(U, size(x) .+ 2)
    field[(begin+1:size(field)[i]-1 for i in 1:N)...] = x
    return field
end

supress(x::Array{U, N}) where {U, N} = x[(begin+1:size(x)[i]-1 for i in 1:N)...]

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

export laplacian, padding, periodicbc!, supress, Δ

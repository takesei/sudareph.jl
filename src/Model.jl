abstract type BaseModel{T<:BaseParams} end
start(mod::BaseModel; kwargs...)::Vector = error("Make subtype of BaseModel and implement start function")

export BaseModel, start

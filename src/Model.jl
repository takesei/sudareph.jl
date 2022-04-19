abstract type BaseModel{T<:BaseParams} end
start(::BaseModel;)::Vector = error("Make subtype of BaseModel and implement start function")

export BaseModel, start

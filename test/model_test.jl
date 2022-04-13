using sudareph, Test

struct Model{T<:BaseParams} <: BaseModel{T} end
struct ModelParams <: BaseParams end

sample = Model{ModelParams}()

@test_throws ErrorException start(sample)

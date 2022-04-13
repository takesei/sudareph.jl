using sudareph, Test, InteractiveUtils

case = [
    (arg=zeros(3, 3), exp=zeros(3, 3)),
    (arg=ones(3, 3),
        exp=[-2 -1 -2; -1 0 -1; -2 -1 -2]),
    (arg=Matrix(reshape(1:9, 3, 3)),
        exp=[2 1 -4; -3 0 -7; -16 -11 -22]'),
]

@testset "laplacian" begin
    for (i, c) in enumerate(case)
        @testset "case $i" begin
            a, e = c[:arg], c[:exp]
            @test laplacian(a) == e
            @test Δ(a) == e
        end
    end
end

Base.@kwdef struct CoordParams <: BaseParams
    C::Const{Float64}
    x::Status{Matrix{Float64}}

    CoordParams(C, x) = new(Const{Float64}(C), Status{Matrix{Float64}}(x))
end

sudareph.save(p::CoordParams) = p.x.value
Base.copy(p::CoordParams) = CoordParams(p[:C], copy(p[:x]))

params = CoordParams(
    C=2,
    x=Matrix(reshape(1:9, 3, 3)),
)

sample = CoordModel{CoordParams}(params |> copy, 1, 1, 1, 3) do st, dt, dx
    dx = st[:C] * st[:x] / dx^2
    params[:x] = st[:x] + dt * dx
    return params
end

@testset "Simulating" begin
    @testset "General Usage" begin
        res = start(sample)
        @test length(res) == 4
        @test res[4] == 27 * reshape(1:9, 3, 3)
        @test res[1] == reshape(1:9, 3, 3)
    end
    @testset "Assiign params via kwargs" begin
        res = start(sample; n_iter=4, save_by=2)
        @test length(res) == 3
        @test res[3] == 81 * reshape(1:9, 3, 3)
        @test res[1] == reshape(1:9, 3, 3)
    end
end

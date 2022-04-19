using sudareph, Test, InteractiveUtils

case = [
    (arg=zeros(3, 3), exp=zeros(3, 3)),
    (arg=ones(3, 3),
        exp=[-2 -1 -2; -1 0 -1; -2 -1 -2]),
    (arg=Matrix(reshape(1:1.0:9, 3, 3)),
        exp=[2 1 -4; -3 0 -7; -16 -11 -22]'),
]

@testset "Coord Status & laplacian" begin
    for (i, c) in enumerate(case)
        @testset "case $i" begin
            a, e = c[:arg], c[:exp]

            temp = CoordStatus(a)
            @test temp.value == a |> padding
            @test laplacian(temp.value) == e
            @test copy(temp).value == temp.value

            t = CoordStatus(a; bc=periodicbc!)
            @test t.value == a |> padding |> periodicbc!
            @test copy(t).value == t.value
        end
    end
    @testset "case Array" begin
        a = Vector{Matrix{Float64}}([case[i].arg for i in 1:length(case)])
        e = Vector{Matrix{Float64}}([case[i].exp for i in 1:length(case)])

        temp = ArrayCoordStatus(a)
        @test temp.value == map(padding, a)
        @test (@. laplacian(temp.value) == e) |> all
        @test copy(temp).value == temp.value

        t = ArrayCoordStatus(a; bc=periodicbc!)
        @test t.value == map(x -> x |> padding |> periodicbc!, a)
        @test copy(t).value == t.value
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
    @testset "Benchmark" begin
        # @show @code_warntype start(sample)
        # @show @code_warntype start(sample; n_iter=3, save_by=1)
    end
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

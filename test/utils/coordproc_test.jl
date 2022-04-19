using sudareph, Test, InteractiveUtils

@testset "padding" begin
    @test [1;] |> padding == [0, 1, 0]
    @test [1;;] |> padding == [0 0 0; 0 1 0; 0 0 0]
    @test [1, 2] |> padding == [0, 1, 2, 0]
    @test [1 2; 3 4] |> padding == [0 0 0 0; 0 1 2 0; 0 3 4 0; 0 0 0 0]
end

@testset "supress" begin
    @test [1;] |> padding |> supress == [1;]
    @test [1;;] |> padding |> supress == [1;;]
    @test [1, 2] |> padding |> supress == [1, 2]
    @test [1 2; 3 4] |> padding |> supress == [1 2; 3 4]
end

@testset "periodic boundary condition" begin
    @test [1;] |> padding |> periodicbc! == ones(3)
    @test [1;;] |> padding |> periodicbc! == ones(3, 3)
    @test [1, 2] |> padding |> periodicbc! == [2, 1, 2, 1]
    @test [1 2; 3 4] |> padding |> periodicbc! == [4 3 4 3; 2 1 2 1; 4 3 4 3; 2 1 2 1]
end

case = [
    (arg=zeros(3, 3), exp=zeros(3, 3)),
    (arg=ones(3, 3),
        exp=[-2 -1 -2; -1 0 -1; -2 -1 -2]),
    (arg=Matrix(reshape(1:1.0:9, 3, 3)),
        exp=[2 1 -4; -3 0 -7; -16 -11 -22]'),
]

@testset "laplacian" begin
    for (i, c) in enumerate(case)
        @testset "case $i" begin
            a, e = c[:arg], c[:exp]
            @test laplacian(a |> padding) == e
            @test Δ(a |> padding) == laplacian(a |> padding)
        end
    end
end

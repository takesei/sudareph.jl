using sudareph, Test

struct Params <: BaseParams
    cval::Const{Float64}
    sval::Status{String}

    Params(cval, sval) = new(Const{Float64}(cval), Status{String}(sval))
end

sample = Params(3.14, "asdf")

@testset "General Params" begin
    @testset "Get" begin
        @test sample[:cval] == 3.14
        @test sample[:sval] == "asdf"
    end

    @testset "Set" begin
        @test_throws ErrorException sample[:cval] = 2.3
        @test sample[:cval] != 2.3

        @test_nowarn sample[:sval] = "nanachi"
        @test sample[:sval] == "nanachi"

        @test_throws TypeError sample[:sval] = [1 2 3]
    end

    @testset "Save" begin
        @test_throws ErrorException save(sample)
        @test_throws ErrorException copy(sample)
    end
end

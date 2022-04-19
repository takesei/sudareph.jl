using sudareph, Test

struct Params <: BaseParams
    cval::Const{Float64}
    sval::Status{String}

    Params(cval, sval) = new(Const{Float64}(cval), Status{String}(sval))
end

struct Var{T} <: BaseVar{T}
    value::T
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

    @testset "Copy & Save" begin
        @test_throws ErrorException save(sample)
        @test_throws ErrorException copy(sample)
        @test_throws ErrorException copy(Var("asdf"))
        @test copy(sample.cval).value == sample.cval.value
        @test copy(sample.sval).value == sample.sval.value
    end

    @testset "Convert" begin
        @test convert(Const, "asdf").value == Const{String}("asdf").value
        @test convert(Status, "asdf").value == Status{String}("asdf").value

        for i in [["asdf", "honya"], ["asdf" "honya"]]
            t = convert(ArrayConst, i)
            @test t.value == i
            @test typeof(t) == ArrayConst{String}

            tc = convert(ArrayStatus, i)
            @test tc.value == i
            @test typeof(tc) == ArrayStatus{String}
        end
    end
end

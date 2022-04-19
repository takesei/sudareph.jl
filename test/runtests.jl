using sudareph, Test, SafeTestsets, JuliaFormatter, Coverage

clean_folder("..")
@time begin
    @time @safetestset "Params" begin
        include("params_test.jl")
    end
    @time @safetestset "Model" begin
        include("model_test.jl")
    end
    @time @safetestset "Utils" begin
        @time @safetestset "CoordProc" begin
            include("utils/coordproc_test.jl")
        end
        @time @safetestset "CoordModel" begin
            include("utils/coordmodel_test.jl")
        end
    end
end

format(".")

# coverage = process_folder("../src")
# analyze_malloc("../src")
# LCOV.writefile("../coverage-lcov.info", coverage)
# clean_folder("..")

using Coverage
# process '*.cov' files
coverage = process_folder("../src") # defaults to src/; alternatively, supply the folder name as argument
# process '*.info' files, if you collected them
coverage = merge_coverage_counts(
    coverage,
    filter!(
        let prefixes = (joinpath(pwd(), "../src", ""))
            c -> any(p -> startswith(c.filename, p), prefixes)
        end,
        LCOV.readfolder(".")),
)
# Get total coverage for all Julia files
LCOV.writefile("../coverage-lcov.info", coverage)

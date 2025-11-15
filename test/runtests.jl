using Test
using RooflinePlots

@testset "RooflinePlots.jl Tests" begin
    @testset "Unit Tests" begin
        @testset "Type Constructors" begin
            include("test_types.jl")
        end

        @testset "Configuration Functions" begin
            include("test_config.jl")
        end

        @testset "Analysis Functions" begin
            include("test_analysis.jl")
        end

        @testset "Reporting Functions" begin
            include("test_reporting.jl")
        end

        @testset "CLI Parsing" begin
            include("test_cli.jl")
        end

        @testset "Plotting Functions" begin
            include("test_plotting.jl")
        end

        @testset "Table Format Output" begin
            include("test_table_formats.jl")
        end
    end

    @testset "Integration Tests" begin
        include("test_integration.jl")
    end
end

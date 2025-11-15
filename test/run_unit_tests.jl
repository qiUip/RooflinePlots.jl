#!/usr/bin/env julia
# Unit test runner with optional filtering
#
# Purpose: Provides a standalone test runner for development and debugging.
#          Allows running specific test suites or cleaning up generated files.
#          For CI/automated testing, use runtests.jl via Pkg.test() instead.
#
# Usage:
#   julia --project=. test/run_unit_tests.jl           # Run all unit tests
#   julia --project=. test/run_unit_tests.jl types     # Run types tests only
#   julia --project=. test/run_unit_tests.jl config    # Run config tests only
#   julia --project=. test/run_unit_tests.jl analysis  # Run analysis tests only
#   julia --project=. test/run_unit_tests.jl reporting # Run reporting tests only
#   julia --project=. test/run_unit_tests.jl cli       # Run CLI parsing tests only
#   julia --project=. test/run_unit_tests.jl plotting  # Run plotting tests only
#   julia --project=. test/run_unit_tests.jl clean     # Clean up generated files

using Test
using RooflinePlots

# Load shared test utilities
include("test_utils.jl")

# Test file mapping
const TEST_FILES = Dict(
    "types" => ("test_types.jl", "Type Constructors"),
    "config" => ("test_config.jl", "Configuration Functions"),
    "analysis" => ("test_analysis.jl", "Analysis Functions"),
    "reporting" => ("test_reporting.jl", "Reporting Functions"),
    "cli" => ("test_cli.jl", "CLI Parsing"),
    "plotting" => ("test_plotting.jl", "Plotting Functions"),
)

# Parse command line arguments
filter_test = length(ARGS) > 0 ? lowercase(ARGS[1]) : nothing

# Handle cleanup
if filter_test == "clean"
    cleanup_examples()
    exit(0)
end

# Run tests
if filter_test === nothing
    # Run all unit tests
    @testset "Unit Tests" begin
        for (key, (file, name)) in sort(collect(TEST_FILES), by = x->x[1])
            @testset "$name" begin
                include(file)
            end
        end
    end
else
    # Run specific test
    if haskey(TEST_FILES, filter_test)
        file, name = TEST_FILES[filter_test]
        @testset "$name" begin
            include(file)
        end
    else
        println("Error: Unknown test filter '$(filter_test)'")
        println("\nAvailable tests:")
        for key in sort(collect(keys(TEST_FILES)))
            println("  - $(key)")
        end
        println("\nUsage: julia --project=. test/run_unit_tests.jl [test_name]")
        exit(1)
    end
end

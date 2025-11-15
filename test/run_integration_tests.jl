#!/usr/bin/env julia
# Integration test runner
#
# Purpose: Provides a standalone runner for integration tests during development.
#          Tests end-to-end functionality and plot generation.
#          For CI/automated testing, use runtests.jl via Pkg.test() instead.
#
# Usage:
#   julia --project=. test/run_integration_tests.jl       # Run integration tests
#   julia --project=. test/run_integration_tests.jl clean # Clean up generated files

using Test
using RooflinePlots

# Load shared test utilities
include("test_utils.jl")

# Handle cleanup argument
if length(ARGS) > 0 && lowercase(ARGS[1]) == "clean"
    cleanup_examples()
    exit(0)
end

# Run integration tests
@testset "Integration Tests" begin
    include("test_integration.jl")
end

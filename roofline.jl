#!/usr/bin/env julia

"""
Roofline Model Plot Generator - Main Entry Point

This script provides a command-line interface for generating Roofline Model plots
and performance analysis. It uses the RooflinePlots module for all functionality.

See --help for usage information.
"""

# Load the module by including it directly
include("src/RooflinePlots.jl")
using .RooflinePlots
using Plots

# Set plotting backend
gr()

"""
    main()

Entry point for the Roofline plot generator. Delegates to run_cli().
"""
function main()
    RooflinePlots.run_cli()
end

# Run main if this script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

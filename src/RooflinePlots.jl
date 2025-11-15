"""
# RooflinePlots

A Julia package for generating Roofline Model visualizations and performance analysis.

The Roofline Model visualizes performance limits based on computational throughput
(FLOP/s) and memory bandwidth (GB/s), identifying whether applications are compute-bound
or memory-bound.

## Main Types
- `RooflineParams`: User-facing parameter specification
- `OutputOptions`: Visualization and output options
- `RooflineConfig`: Internal configuration (created by `params_to_config`)
- `ComputeRoof`, `MemoryLevel`, `Measurement`: Core data structures

## Main Functions
- `create_roofline_plot`: Create Roofline plots
- `print_performance_table`: Display performance metrics
- `determine_bottleneck`: Identify performance bottleneck
- `params_to_config`: Convert parameters to configuration
"""
module RooflinePlots

# Include all submodules
include("types.jl")
include("utils.jl")
include("config.jl")
include("analysis.jl")
include("plotting.jl")
include("reporting.jl")
include("cli.jl")

# Export types
export ComputeRoof, MemoryLevel, Measurement, RooflineConfig, RooflineParams, OutputOptions

# Export configuration functions
export params_to_config, generate_output_filename, parse_color, parse_color_palette

# Export analysis functions
export determine_bottleneck

# Export plotting functions
export create_roofline_plot, plot_roofline!

# Export reporting functions
export print_performance_table

# Export CLI functions
export parse_commandline, run_cli, get_table_file_extension

end # module RooflinePlots

# API Reference

Complete API documentation for RooflinePlots.jl.

## Module

```@docs
RooflinePlots
```

## Core Types

```@docs
ComputeRoof
MemoryLevel
Measurement
RooflineConfig
RooflineParams
OutputOptions
```

## Configuration Functions

```@docs
params_to_config
RooflinePlots.get_measured_flops
RooflinePlots.assign_colors!
generate_output_filename
RooflinePlots.MEMORY_COLORS
RooflinePlots.parse_color
RooflinePlots.parse_color_palette
```

## Utility Functions

```@docs
RooflinePlots.find_combined_group
RooflinePlots.are_in_same_group
RooflinePlots.calculate_arithmetic_intensity
RooflinePlots.find_memory_level
RooflinePlots.find_compute_roof
```

## Analysis Functions

```@docs
determine_bottleneck
```

## Plotting Functions

```@docs
create_roofline_plot
plot_roofline!
```

## Reporting Functions

```@docs
print_performance_table
```

## CLI Functions

```@docs
run_cli
parse_commandline
get_table_file_extension
RooflinePlots.validate_positive
RooflinePlots.print_help
```

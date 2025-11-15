"""
    ComputeRoof

Represents a compute performance ceiling in the Roofline Model.

# Fields
- `name::String`: Compute type identifier (e.g., "DP", "SP", "DP_AVX")
- `peak_flops::Float64`: Peak performance in GFLOP/s
- `color::Union{Symbol,String}`: Color for plotting (Symbol for color names, String for hex)
"""
struct ComputeRoof
    name::String
    peak_flops::Float64
    color::Union{Symbol,String}
end

"""
    MemoryLevel

Represents a memory hierarchy level with its peak bandwidth.

# Fields
- `name::String`: Memory level identifier (e.g., "DRAM", "L3", "L2", "L1")
- `peak_bw::Float64`: Peak bandwidth in GB/s
- `color::Union{Symbol,String}`: Color for plotting (Symbol for color names, String for hex)
"""
struct MemoryLevel
    name::String
    peak_bw::Float64
    color::Union{Symbol,String}
end

"""
    Measurement

A single performance measurement point on the Roofline plot.

# Fields
- `compute_name::String`: Compute type (e.g., "DP", "SP")
- `memory_name::String`: Memory level (e.g., "DRAM", "L3")
- `flops::Float64`: Measured performance in GFLOP/s
- `bandwidth::Float64`: Measured bandwidth in GB/s
"""
struct Measurement
    compute_name::String
    memory_name::String
    flops::Float64
    bandwidth::Float64
end

"""
    RooflineConfig

Internal configuration for Roofline plot generation.

Created by `params_to_config()` from `RooflineParams` and `OutputOptions`.
Contains processed roofs, memory levels, measurements, and display settings.

Users should work with `RooflineParams` and `OutputOptions` instead of constructing this directly.
"""
struct RooflineConfig
    compute_roofs::Vector{ComputeRoof}
    memory_levels::Vector{MemoryLevel}
    measurements::Vector{Measurement}
    combined_compute_groups::Vector{Vector{String}}
    num_cores::Int
    topology::String
    cpu_name::String
    app_name::String
    simple_mode::Bool
    table_format::String
end

"""
    RooflineParams

User-facing parameter specification for Roofline analysis.

Supports arbitrary memory types (DRAM, L3, HBM, etc.) and compute types (DP, SP, TENSOR, etc.).
Each type requires a peak value and optionally a measured value.

Combined measurements allow a single measured value to apply to multiple compute types.

# Fields
- `memory_specs`: Dict mapping memory type names to (peak, measured) bandwidth in GB/s
- `compute_specs`: Dict mapping compute type names to (peak, measured) FLOPS in GFLOP/s
- `combined_flops`: Single measured value applying to all compute types (optional)
- `combined_flops_groups`: List of (types, measured) for specific combined groups (optional)
- `num_cores`, `topology`, `cpu_name`, `app_name`: Metadata for plot title and filenames
"""
struct RooflineParams
    memory_specs::Dict{
        String,
        @NamedTuple{peak::Union{Float64,Nothing},measured::Union{Float64,Nothing}}
    }
    compute_specs::Dict{
        String,
        @NamedTuple{peak::Union{Float64,Nothing},measured::Union{Float64,Nothing}}
    }
    combined_flops::Union{Float64,Nothing}
    combined_flops_groups::Vector{Tuple{Vector{String},Float64}}
    num_cores::Int
    topology::String
    cpu_name::String
    app_name::String
end

"""
    OutputOptions

Visualization and output formatting options for Roofline plots and tables.

# Fields
- `force_simple`: Force linear scale plotting instead of log-log (default: false)
- `table_format`: Table format: "ascii", "org", "markdown", or "csv" (default: "ascii")
- `mem_colors`: Custom color palette for memory levels (optional)
- `compute_colors`: Custom color palette for compute types (optional)
- `plot_format`: Plot file format: "png", "pdf", or "svg" (default: "png")

Use keyword constructor to override defaults:
```julia
OutputOptions(plot_format="pdf", table_format="markdown")
```
"""
struct OutputOptions
    force_simple::Bool
    table_format::String
    mem_colors::Union{Vector{Union{Symbol,String}},Nothing}
    compute_colors::Union{Vector{Union{Symbol,String}},Nothing}
    plot_format::String
end

# Outer constructor with keyword arguments and defaults
function OutputOptions(;
    force_simple::Bool = false,
    table_format = "ascii",
    mem_colors = nothing,
    compute_colors = nothing,
    plot_format = "svg",
)
    # Convert to proper types, allowing flexible input
    table_format_str = String(table_format)
    plot_format_str = String(plot_format)

    # Convert color vectors to the right type if provided
    mem_colors_typed = if isnothing(mem_colors)
        nothing
    else
        Union{Symbol,String}[mem_colors...]
    end

    compute_colors_typed = if isnothing(compute_colors)
        nothing
    else
        Union{Symbol,String}[compute_colors...]
    end

    return OutputOptions(
        force_simple,
        table_format_str,
        mem_colors_typed,
        compute_colors_typed,
        plot_format_str,
    )
end

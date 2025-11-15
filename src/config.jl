"""
Configuration module for converting user parameters to Roofline configuration.
"""

"""
Default color palettes for memory levels (cool tones) and compute types (warm tones).
"""
const MEMORY_COLORS =
    [:blue, :darkgreen, :purple, :teal, :navy, :indigo, :steelblue, :darkslateblue]
const COMPUTE_COLORS =
    [:red, :darkorange, :brown, :crimson, :chocolate, :firebrick, :maroon, :sienna]

"""
    parse_color(color_str::AbstractString) -> Union{Symbol, String}

Parse a color string. Supports color names ("red", "blue") and hex colors ("#FF5733").
"""
function parse_color(color_str::AbstractString)
    # Trim whitespace
    color_str = strip(color_str)

    # Check if it's a hex color (starts with #)
    if startswith(color_str, "#")
        # Validate hex format: #RGB or #RRGGBB
        hex_part = color_str[2:end]
        if length(hex_part) == 3 || length(hex_part) == 6
            # Check if all characters are valid hex digits
            if all(c -> c in "0123456789ABCDEFabcdef", hex_part)
                return String(color_str)  # Convert SubString to String for hex colors
            end
        end
        error("Invalid hex color format: $color_str. Expected #RGB or #RRGGBB.")
    end

    # Otherwise, treat as color name and convert to symbol
    # Basic validation: check for reasonable color name (alphanumeric + common chars)
    if isempty(color_str) || !all(c -> isletter(c) || isdigit(c), color_str)
        error(
            "Invalid color name: $color_str. Color names should contain only letters and digits.",
        )
    end

    return Symbol(lowercase(color_str))
end

"""
    parse_color_palette(palette_str::AbstractString) -> Vector{Union{Symbol, String}}

Parse a comma-separated color palette string (e.g., "red,blue,#FF5733").
"""
function parse_color_palette(palette_str::AbstractString)
    colors = Union{Symbol,String}[]
    color_strs = split(palette_str, ",")

    if isempty(color_strs) || all(isempty ∘ strip, color_strs)
        error("Color palette cannot be empty")
    end

    for color_str in color_strs
        color_str = strip(color_str)
        if !isempty(color_str)
            push!(colors, parse_color(color_str))
        end
    end

    return colors
end

"""
    assign_colors!(items::Vector{T}, user_colors, default_palette, constructor)

Assign colors to items from user palette or default palette, reconstructing items with assigned colors.
"""
function assign_colors!(
    items::Vector{T},
    user_colors,
    default_palette,
    constructor,
) where {T}
    for (i, item) in enumerate(items)
        color = if !isnothing(user_colors) && i <= length(user_colors)
            user_colors[i]
        else
            color_idx = mod1(i, length(default_palette))
            default_palette[color_idx]
        end
        items[i] = constructor(item, color)
    end
end

"""
    get_measured_flops(params::RooflineParams, compute_name::String) -> Union{Float64, Nothing}

Retrieve measured FLOPS value for a compute type (checks individual, combined, and group measurements).
"""
function get_measured_flops(params::RooflineParams, compute_name::String)
    # Check if this compute type has a specific measurement
    if haskey(params.compute_specs, compute_name)
        measured = params.compute_specs[compute_name].measured
        if !isnothing(measured)
            return measured
        end
    end

    # Check if there's a combined measurement for all types
    if !isnothing(params.combined_flops)
        return params.combined_flops
    end

    # Check if this type is in a combined group
    for (types, value) in params.combined_flops_groups
        if compute_name in types
            return value
        end
    end

    return nothing
end


"""
    params_to_config(params::RooflineParams, output_opts::OutputOptions=OutputOptions()) -> RooflineConfig

Convert user parameters to internal configuration for plotting and reporting.

Processes memory/compute specs, creates measurements, assigns colors, and determines
display mode (simple vs hierarchical). Fully generic - supports any type names.
"""
function params_to_config(params::RooflineParams, output_opts::OutputOptions)
    compute_roofs = ComputeRoof[]
    memory_levels = MemoryLevel[]
    measurements = Measurement[]

    # Validation: Ensure at least one memory level and one compute type is specified
    if isempty(params.memory_specs)
        error("At least one memory level must be specified (--peak-bw-<TYPE>)")
    end
    if isempty(params.compute_specs)
        error("At least one compute type must be specified (--peak-flops-<TYPE>)")
    end

    # Build all memory levels from generic specifications
    # Each peak MUST have matching measurement (strict 1:1 pairing)
    memory_measured_map = Dict{String,Float64}()

    for (type_name, spec) in params.memory_specs
        if !isnothing(spec.peak)
            if !isnothing(spec.measured)
                # Valid: peak and measurement both specified
                # Color will be assigned after sorting
                push!(memory_levels, MemoryLevel(type_name, spec.peak, :black))
                memory_measured_map[type_name] = spec.measured
            else
                # Warning: peak specified but no measurement
                @warn "Peak bandwidth for $type_name specified ($(spec.peak) GB/s) but no measured-bw-$type_name provided. Skipping $type_name."
            end
        end
    end

    # Ensure at least one valid memory level exists
    if isempty(memory_levels)
        error(
            "No valid memory levels found. Each --peak-bw-<type> requires a matching --measured-bw-<type>.",
        )
    end

    # Sort memory levels by bandwidth (descending: fastest first, slowest last)
    sort!(memory_levels, by = m -> m.peak_bw, rev = true)

    # Assign colors from user palette (if provided) or default palette
    assign_colors!(
        memory_levels,
        output_opts.mem_colors,
        MEMORY_COLORS,
        (ml, color) -> MemoryLevel(ml.name, ml.peak_bw, color),
    )

    # Determine the primary (slowest/main) memory level - used for initial measurements
    # After sorting descending, this is the last element
    primary_memory = memory_levels[end]
    primary_measured_bw = memory_measured_map[primary_memory.name]

    # Build compute roofs from generic specifications
    for (type_name, spec) in params.compute_specs
        if !isnothing(spec.peak)
            # Color will be assigned after sorting
            push!(compute_roofs, ComputeRoof(type_name, spec.peak, :black))
        end
    end

    # Sort compute roofs by performance (ascending: lowest first, highest last)
    sort!(compute_roofs, by = r -> r.peak_flops)

    # Assign colors from user palette (if provided) or default palette
    assign_colors!(
        compute_roofs,
        output_opts.compute_colors,
        COMPUTE_COLORS,
        (roof, color) -> ComputeRoof(roof.name, roof.peak_flops, color),
    )

    # Create initial measurements at primary memory level
    for roof in compute_roofs
        roof_measured = get_measured_flops(params, roof.name)
        if !isnothing(roof_measured)
            push!(
                measurements,
                Measurement(
                    roof.name,
                    primary_memory.name,
                    roof_measured,
                    primary_measured_bw,
                ),
            )
        end
    end

    # Create measurements for additional memory levels (if any)
    for memory_level in memory_levels
        if memory_level.name == primary_memory.name
            continue  # Skip primary level (already handled above)
        end

        # Get measured bandwidth for this memory level
        measured_bw = memory_measured_map[memory_level.name]

        # Create measurements for all compute types at this memory level
        if !isnothing(measured_bw)
            for roof in compute_roofs
                roof_measured = get_measured_flops(params, roof.name)
                if !isnothing(roof_measured)
                    push!(
                        measurements,
                        Measurement(
                            roof.name,
                            memory_level.name,
                            roof_measured,
                            measured_bw,
                        ),
                    )
                end
            end
        end
    end

    # Build combined compute groups from combined measurements
    # Groups track which compute types share the same measured value
    combined_compute_groups = Vector{Vector{String}}()

    # Add groups from explicit combined_flops_groups parameter
    for (types, _) in params.combined_flops_groups
        push!(combined_compute_groups, types)
    end

    # Detect implicit combined groups: types without specific measurements that share combined_flops
    if !isnothing(params.combined_flops)
        # Find all types that don't have specific measurements
        types_without_specific = String[]
        for roof in compute_roofs
            if !haskey(params.compute_specs, roof.name) ||
               isnothing(params.compute_specs[roof.name].measured)
                push!(types_without_specific, roof.name)
            end
        end

        # If multiple types share the combined measurement, they form a group
        if length(types_without_specific) > 1
            push!(combined_compute_groups, types_without_specific)
        end
    end

    # Determine plotting mode: simple (linear) or hierarchical (log-log)
    simple_mode = output_opts.force_simple || length(memory_levels) == 1

    return RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        combined_compute_groups,
        params.num_cores,
        params.topology,
        params.cpu_name,
        params.app_name,
        simple_mode,
        output_opts.table_format,
    )
end

# Convenience overload with default OutputOptions
function params_to_config(params::RooflineParams)
    return params_to_config(params, OutputOptions())
end

"""
    generate_output_filename(params::RooflineParams, hierarchical::Bool, format::String="png") -> String

Generate output filename based on CPU, topology, plot type, and format.
"""
function generate_output_filename(
    params::RooflineParams,
    hierarchical::Bool,
    format::String = "png",
)
    topo_clean = replace(lowercase(params.topology), " " => "_")
    cpu_clean = replace(params.cpu_name, " " => "_", "-" => "_")
    prefix = hierarchical ? "roofline_hierarchical" : "roofline"

    # Include cores in filename only if specified (not default value of 1)
    cores_str = params.num_cores > 1 ? "_$(params.num_cores)cores" : ""

    return "$(prefix)_$(cpu_clean)$(cores_str)_$(topo_clean).$(format)"
end

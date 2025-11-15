"""
Performance analysis module for Roofline Model bottleneck detection.
"""

"""
    determine_bottleneck(config::RooflineConfig) -> String

Identify primary performance bottleneck by comparing arithmetic intensity against ridge points.

Returns the highest-priority bottleneck: memory-bound (by level and type) or compute-bound.
Handles combined measurements and flexible memory hierarchies.
"""
function determine_bottleneck(config::RooflineConfig)
    if isempty(config.measurements)
        return "Unknown (no measurements)"
    end

    # Categorize all measurements by (memory_level, compute_name) pairs
    memory_bound = Dict{String,Set{String}}()  # memory_level => Set of compute_names that are memory-bound
    compute_bound = Set{String}()  # Set of compute_names that are compute-bound

    for measurement in config.measurements
        # Find the corresponding memory level
        memory_level = find_memory_level(config, measurement.memory_name)
        if isnothing(memory_level)
            continue
        end
        peak_bw = memory_level.peak_bw

        # Calculate arithmetic intensity
        ai = calculate_arithmetic_intensity(measurement)

        # Check this measurement against ALL compute roofs that could apply
        # Using combined_compute_groups to determine if measurement applies to multiple roofs
        for roof in config.compute_roofs
            # Determine if this roof could apply to this measurement
            applies =
                roof.name == measurement.compute_name ||
                are_in_same_group(config, measurement.compute_name, roof.name)

            if applies
                ridge_point = roof.peak_flops / peak_bw

                # Categorize exactly at ridge point
                if ai < ridge_point
                    # Memory-bound for this roof at this memory level
                    if !haskey(memory_bound, measurement.memory_name)
                        memory_bound[measurement.memory_name] = Set{String}()
                    end
                    push!(memory_bound[measurement.memory_name], roof.name)
                elseif ai > ridge_point
                    # Compute-bound for this roof
                    push!(compute_bound, roof.name)
                end
            end
        end
    end

    # Priority 1-N: Check memory-bound levels from slowest to fastest
    # Memory levels are sorted descending (fastest first), so reverse for priority order
    for mem_level in reverse(config.memory_levels)
        mem_name = mem_level.name
        if haskey(memory_bound, mem_name) && !isempty(memory_bound[mem_name])
            # Found memory bottleneck at this level
            # Collect compute types in order from sorted compute_roofs (ascending by performance)
            bound_types = String[]
            for roof in config.compute_roofs
                if roof.name in memory_bound[mem_name]
                    push!(bound_types, roof.name)
                end
            end

            if !isempty(bound_types)
                compute_str = join(bound_types, "+")
                return "Memory-bound ($compute_str/$mem_name)"
            end
        end
    end

    # Priority 5: Check compute-bound
    if !isempty(compute_bound)
        return "Compute-bound"
    end

    return "Unknown"
end

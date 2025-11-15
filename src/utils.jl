"""
Utility functions shared across analysis, plotting, and reporting modules.
"""

"""
    find_combined_group(config::RooflineConfig, type_name::String) -> Union{Vector{String}, Nothing}

Find the combined compute group containing the given type name. Returns the group or nothing.
"""
function find_combined_group(config::RooflineConfig, type_name::String)
    for group in config.combined_compute_groups
        if type_name in group
            return group
        end
    end
    return nothing
end

"""
    are_in_same_group(config::RooflineConfig, type1::String, type2::String) -> Bool

Check if two compute types are in the same combined group.
"""
function are_in_same_group(config::RooflineConfig, type1::String, type2::String)
    for group in config.combined_compute_groups
        if type1 in group && type2 in group
            return true
        end
    end
    return false
end

"""
    calculate_arithmetic_intensity(measurement::Measurement) -> Float64

Calculate arithmetic intensity (FLOP/Byte) as flops / bandwidth.
"""
function calculate_arithmetic_intensity(measurement::Measurement)
    return measurement.flops / measurement.bandwidth
end

"""
    find_memory_level(config::RooflineConfig, name::String) -> Union{MemoryLevel, Nothing}

Find memory level by name. Returns the MemoryLevel or nothing.
"""
function find_memory_level(config::RooflineConfig, name::String)
    idx = findfirst(m -> m.name == name, config.memory_levels)
    return isnothing(idx) ? nothing : config.memory_levels[idx]
end

"""
    find_compute_roof(config::RooflineConfig, name::String) -> Union{ComputeRoof, Nothing}

Find compute roof by name. Returns the ComputeRoof or nothing.
"""
function find_compute_roof(config::RooflineConfig, name::String)
    idx = findfirst(r -> r.name == name, config.compute_roofs)
    return isnothing(idx) ? nothing : config.compute_roofs[idx]
end

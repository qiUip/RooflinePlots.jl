"""
Performance reporting module for formatted ASCII tables.
"""

using Printf

"""
    print_performance_table(config::RooflineConfig)

Print a formatted table of performance metrics and bottleneck analysis.

Shows measured vs peak performance for compute types and memory levels, arithmetic intensity,
and bottleneck. Supports multiple table formats (ascii, org, markdown, csv). Handles combined measurements.
"""
function print_performance_table(config::RooflineConfig)
    if isempty(config.measurements)
        println("No measurements to display.")
        return
    end

    # Collect all rows first to determine optimal column width
    rows = Vector{Tuple{String,String}}()

    # Group measurements by compute type and memory level
    compute_measurements = Dict{String,Vector{Measurement}}()
    memory_measurements = Dict{String,Vector{Measurement}}()

    for measurement in config.measurements
        # Group by compute type
        if !haskey(compute_measurements, measurement.compute_name)
            compute_measurements[measurement.compute_name] = Measurement[]
        end
        push!(compute_measurements[measurement.compute_name], measurement)

        # Group by memory level
        if !haskey(memory_measurements, measurement.memory_name)
            memory_measurements[measurement.memory_name] = Measurement[]
        end
        push!(memory_measurements[measurement.memory_name], measurement)
    end

    # Collect compute metrics for all types (generic approach)
    # Process types in sorted order (by peak performance)
    already_reported = Set{String}()

    for roof in config.compute_roofs
        compute_type = roof.name

        # Skip if already reported as part of a combined group
        if compute_type in already_reported
            continue
        end

        # Check if this type has measurements
        if !haskey(compute_measurements, compute_type)
            continue
        end

        measurements = compute_measurements[compute_type]
        measured_flops = measurements[1].flops

        # Check if this type is part of a combined group
        combined_group = find_combined_group(config, compute_type)

        if !isnothing(combined_group) && length(combined_group) > 1
            # Combined measurement - show for all types in the group
            group_str = join(combined_group, "+")

            # Show the measured value once
            push!(
                rows,
                ("Measured $group_str Compute", @sprintf("%7.1f GFLOP/s", measured_flops)),
            )

            # Show percentage for each type in the group
            for group_type in combined_group
                group_roof = find_compute_roof(config, group_type)
                if !isnothing(group_roof)
                    peak = group_roof.peak_flops
                    percent = (measured_flops / peak) * 100
                    push!(
                        rows,
                        ("Percentage of Peak $group_type", @sprintf("%14.1f%%", percent)),
                    )
                end
                push!(already_reported, group_type)
            end
        else
            # Individual measurement
            peak = roof.peak_flops
            percent = (measured_flops / peak) * 100
            push!(
                rows,
                (
                    "Measured $compute_type Compute",
                    @sprintf("%7.1f GFLOP/s", measured_flops)
                ),
            )
            push!(rows, ("Percentage of Peak $compute_type", @sprintf("%14.1f%%", percent)))
            push!(already_reported, compute_type)
        end
    end

    # Collect memory bandwidth metrics
    # Display in order from fastest to slowest (memory_levels is already sorted descending)
    for memory_level in config.memory_levels
        memory_name = memory_level.name
        if !haskey(memory_measurements, memory_name)
            continue
        end

        measurements = memory_measurements[memory_name]
        # Use the first measurement for this memory level (they should all have the same bandwidth)
        measured_bw = measurements[1].bandwidth

        # Get peak bandwidth from the memory_level we're iterating over
        peak_bw = memory_level.peak_bw
        bw_percent = (measured_bw / peak_bw) * 100

        push!(
            rows,
            ("Measured $memory_name Bandwidth", @sprintf("%10.2f GB/s", measured_bw)),
        )
        push!(
            rows,
            ("Percentage of Peak $memory_name BW", @sprintf("%14.1f%%", bw_percent)),
        )
    end

    # Collect arithmetic intensity for each measurement
    # Track which measurements we've already reported to avoid duplicates for combined groups
    reported_ai = Set{Tuple{String,String}}()

    for measurement in config.measurements
        # Skip if already reported
        key = (measurement.compute_name, measurement.memory_name)
        if key in reported_ai
            continue
        end

        ai = calculate_arithmetic_intensity(measurement)

        # Check if this type is part of a combined group
        combined_group = find_combined_group(config, measurement.compute_name)

        # Generate label based on whether it's combined or not
        ai_label = if !isnothing(combined_group) && length(combined_group) > 1
            # Combined group - use group name for AI label
            group_str = join(combined_group, "+")
            "$(group_str)/$(measurement.memory_name) AI"
        else
            # Individual measurement
            "$(measurement.compute_name)/$(measurement.memory_name) AI"
        end

        push!(rows, (ai_label, @sprintf("%8.2f FLOP/B", ai)))

        # Mark all types in the combined group as reported for this memory level
        if !isnothing(combined_group)
            for group_type in combined_group
                push!(reported_ai, (group_type, measurement.memory_name))
            end
        else
            push!(reported_ai, key)
        end
    end

    # Collect bottleneck
    bottleneck = determine_bottleneck(config)
    push!(rows, ("Bottleneck", bottleneck))

    # Calculate optimal widths
    metric_width = maximum(length(row[1]) for row in rows)
    metric_width = max(metric_width, length("Metric")) + 2  # Add padding

    value_width = maximum(length(row[2]) for row in rows)
    value_width = max(value_width, length("Value")) + 2  # Add padding

    # Handle CSV format separately (no table borders)
    if config.table_format == "csv"
        println("Metric,Value")
        for (metric, value) in rows
            # Quote values that contain special characters (comma, quotes, parentheses, newlines)
            needs_quoting_metric = occursin(r"[,\"\(\)\n]", metric)
            needs_quoting_value = occursin(r"[,\"\(\)\n]", value)

            metric_escaped = needs_quoting_metric ? "\"$metric\"" : metric
            value_escaped = needs_quoting_value ? "\"$value\"" : value

            println("$metric_escaped,$value_escaped")
        end
        return
    end

    # Generate separator line based on table format
    line = if config.table_format == "ascii"
        "+" * "-"^metric_width * "+" * "-"^value_width * "+"
    elseif config.table_format == "org"
        "|" * "-"^metric_width * "+" * "-"^value_width * "|"
    else  # markdown
        "|" * "-"^metric_width * "|" * "-"^value_width * "|"
    end

    # Print top line (except for markdown)
    if config.table_format != "markdown"
        println(line)
    end

    # Print header
    @printf("| %-*s | %*s |\n", metric_width-2, "Metric", value_width-2, "Value")
    println(line)

    # Print data rows
    for (metric, value) in rows
        @printf("| %-*s | %*s |\n", metric_width-2, metric, value_width-2, value)
    end

    # Print bottom line (except for markdown)
    if config.table_format != "markdown"
        println(line)
    end
end

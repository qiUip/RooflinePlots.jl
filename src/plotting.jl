"""
Plotting module for Roofline Model visualization.
"""

using Plots
using Printf

"""
    plot_roofline!(plt, config::RooflineConfig; show_ridges::Bool=true)

Add Roofline elements (roofs, memory lines, ridges, measurements, labels) to an existing plot.
"""
function plot_roofline!(plt, config::RooflineConfig; show_ridges::Bool = true)
    top_roof = maximum(r -> r.peak_flops, config.compute_roofs)
    bottom_roof = minimum(r -> r.peak_flops, config.compute_roofs)
    fastest_memory = maximum(m -> m.peak_bw, config.memory_levels)
    slowest_memory = minimum(m -> m.peak_bw, config.memory_levels)

    # Calculate dynamic axis limits based on actual data
    # ymin: Use 50% of bottom roof or lowest measurement, whichever is lower
    min_measurement_flops =
        isempty(config.measurements) ? bottom_roof :
        minimum(m -> m.flops, config.measurements)
    ymin = min(bottom_roof, min_measurement_flops) * 0.5

    ymax = top_roof * 1.2

    # xmin: Based on ridge point of fastest memory or measurements
    if !isempty(config.measurements)
        min_ai = minimum(m -> m.flops / m.bandwidth, config.measurements)
        xmin =
            config.simple_mode ?
            max(0.5, min(bottom_roof / fastest_memory * 0.2, min_ai * 0.5)) :
            max(0.1, min((top_roof / fastest_memory) * 0.15, min_ai * 0.5))
    else
        xmin =
            config.simple_mode ? max(0.5, bottom_roof / fastest_memory * 0.2) :
            max(0.1, (top_roof / fastest_memory) * 0.15)
    end

    # xmax: Based on ridge point of slowest memory or measurements
    if !isempty(config.measurements)
        max_ai = maximum(m -> m.flops / m.bandwidth, config.measurements)
        # In simple mode, cap based on data; in log-log mode, extend further for visibility
        xmax =
            config.simple_mode ? max(top_roof / slowest_memory * 2.0, max_ai * 1.5) :
            max(top_roof / slowest_memory * 5.0, max_ai * 10.0)
    else
        xmax =
            config.simple_mode ? top_roof / slowest_memory * 2.0 :
            top_roof / slowest_memory * 5.0
    end

    if config.simple_mode && xmax - xmin < 5
        xmax = xmin + 5
    end

    # Draw memory bandwidth lines
    for memory in config.memory_levels
        x_end = top_roof / memory.peak_bw
        plot!(
            plt,
            [xmin, x_end],
            [xmin * memory.peak_bw, top_roof],
            label = "",
            color = memory.color,
            linewidth = 2.5,
        )
    end

    # Draw compute roofs (horizontal lines)
    for roof in config.compute_roofs
        x_start = roof.peak_flops / fastest_memory
        plot!(
            plt,
            [x_start, xmax],
            [roof.peak_flops, roof.peak_flops],
            label = "",
            color = roof.color,
            linewidth = 2.5,
        )
    end

    # Draw ridge point lines (vertical dashed lines)
    if show_ridges
        for roof in config.compute_roofs
            for memory in config.memory_levels
                ridge_ai = roof.peak_flops / memory.peak_bw
                # Only draw if ridge point is within visible range
                if ridge_ai >= xmin && ridge_ai <= xmax
                    plot!(
                        plt,
                        [ridge_ai, ridge_ai],
                        [ymin, roof.peak_flops],
                        label = "",
                        color = memory.color,
                        linestyle = :dash,
                        linewidth = 1.5,
                        alpha = 0.6,
                    )
                end
            end
        end
    end

    # Draw measurement points
    # Track unique points to avoid plotting duplicates for combined measurements
    plotted_points = Set{Tuple{String,Float64,Float64}}()

    # Determine if we need compute-colored strokes
    # Count distinct compute groups (individual types or combined groups)
    distinct_compute_groups = Set{String}()
    for measurement in config.measurements
        # Find if this compute type is in a combined group
        combined_group = find_combined_group(config, measurement.compute_name)
        if !isnothing(combined_group)
            # Use sorted group as identifier to ensure consistency
            group_key = join(sort(combined_group), "+")
            push!(distinct_compute_groups, group_key)
        else
            # If not in a combined group, use the type itself
            push!(distinct_compute_groups, measurement.compute_name)
        end
    end
    use_compute_strokes = length(distinct_compute_groups) > 1

    for measurement in config.measurements
        ai = calculate_arithmetic_intensity(measurement)

        # Create unique key: (memory_name, ai, flops)
        # This ensures we only plot one point per unique measurement location
        point_key = (measurement.memory_name, ai, measurement.flops)

        # Skip if we've already plotted this exact point
        if point_key in plotted_points
            continue
        end
        push!(plotted_points, point_key)

        memory_level = find_memory_level(config, measurement.memory_name)
        compute_roof = find_compute_roof(config, measurement.compute_name)

        fill_color = memory_level.color
        stroke_color = use_compute_strokes ? compute_roof.color : fill_color

        label_text =
            use_compute_strokes ? "$(measurement.compute_name)/$(measurement.memory_name)" :
            measurement.memory_name

        scatter!(
            plt,
            [ai],
            [measurement.flops],
            label = "$(label_text) (AI=$(round(ai, digits=1)))",
            markersize = 8,
            color = fill_color,
            markerstrokecolor = stroke_color,
            markerstrokewidth = 1,
        )
    end

    # Add labels for compute roofs
    for roof in config.compute_roofs
        # Use consistent visual offset as percentage of y-axis range
        # Simple mode: 2% of y-range for consistent visual spacing regardless of roof values
        # Log-log mode: 3% offset from roof value
        if config.simple_mode
            offset_y = (ymax - ymin) * 0.02
            y_pos = roof.peak_flops + offset_y
        else
            offset_factor = 1.03
            y_pos = roof.peak_flops * offset_factor
        end

        # Align all labels to the right with small offset 
        x_offset =
            config.simple_mode ? (xmax - xmin) * 0.03 : (log10(xmax) - log10(xmin)) * 0.03
        x_pos = config.simple_mode ? xmax - x_offset : xmax / (10^x_offset)

        annotate!(
            plt,
            x_pos,
            y_pos,
            text(
                @sprintf("%s: %.0f GFLOP/s", roof.name, roof.peak_flops),
                10,
                roof.color,
                :bottom,
                :right,
            ),
        )
    end

    # Add labels for memory levels
    if !config.simple_mode
        # Log-log mode: calculate rotation based on visual slope
        log_y_range = log10(ymax) - log10(ymin)
        log_x_range = log10(xmax) - log10(xmin)

        # Calculate visual slope for bandwidth lines on log-log plot
        # Effective plot area after margins: ~850x540 pixels
        effective_width = 850.0
        effective_height = 540.0
        visual_slope = (effective_height / log_y_range) / (effective_width / log_x_range)
        rotation = rad2deg(atan(visual_slope))

        for memory in config.memory_levels
            idx = findfirst(m -> m.name == memory.name, config.memory_levels)
            y_factor = 1.8 - (idx-1) * 0.25
            target_y = ymin * y_factor
            natural_label_x = target_y / memory.peak_bw

            if natural_label_x >= xmin * 1.1
                label_x = natural_label_x
                label_y = target_y * 1.06
            else
                label_x = xmin * 1.2
                label_y = label_x * memory.peak_bw * 1.06
            end

            annotate!(
                plt,
                label_x,
                label_y,
                text(
                    @sprintf("%s: %.0f GB/s", memory.name, memory.peak_bw),
                    10,
                    memory.color,
                    :bottom,
                    :left,
                    rotation = rotation,
                ),
            )
        end
    else
        # Simple mode: calculate rotation based on linear slope
        for memory in config.memory_levels
            ridge_x = top_roof / memory.peak_bw
            label_x = xmin + (ridge_x - xmin) * 0.4
            label_y = memory.peak_bw * label_x
            y_range = ymax - ymin
            x_range = xmax - xmin
            aspect_factor = (x_range / y_range) * 0.7
            visual_slope = memory.peak_bw * aspect_factor
            rotation = rad2deg(atan(visual_slope))

            # Use smaller offset (6%) to keep labels closer to lines
            annotate!(
                plt,
                label_x,
                label_y * 1.06,
                text(
                    @sprintf("%s: %.1f GB/s", memory.name, memory.peak_bw),
                    10,
                    memory.color,
                    :bottom,
                    :left,
                    rotation = rotation,
                ),
            )
        end
    end

    # Set axis limits
    xlims!(plt, xmin, xmax)
    ylims!(plt, ymin, ymax)
end

"""
    create_roofline_plot(config::RooflineConfig; show_ridges::Bool=true) -> Plots.Plot

Create a complete Roofline plot from configuration (linear or log-log based on config.simple_mode).
"""
function create_roofline_plot(config::RooflineConfig; show_ridges::Bool = true)
    title_type = config.simple_mode ? "Roofline Analysis" : "Hierarchical Roofline"
    title_text = "$title_type: $(config.app_name)\n$(config.num_cores) cores, $(config.topology), $(config.cpu_name)"

    xscale = config.simple_mode ? :identity : :log10
    yscale = config.simple_mode ? :identity : :log10

    plt = plot(
        xlabel = "Arithmetic Intensity (FLOP/Byte)",
        ylabel = "Performance (GFLOP/s)",
        title = title_text,
        xscale = xscale,
        yscale = yscale,
        legend = :bottomright,
        size = (1000, 700),
        dpi = 300,
        grid = true,
        gridalpha = 0.2,
        gridstyle = :solid,
        framestyle = :box,
        titlefontsize = 13,
        labelfontsize = 12,
        legendfontsize = 9,
        margin = 5Plots.mm,
    )

    plot_roofline!(plt, config, show_ridges = show_ridges)

    return plt
end

"""
    create_roofline_plot(params::RooflineParams, output_opts::OutputOptions=OutputOptions(); show_ridges::Bool=true) -> Plots.Plot

Create a Roofline plot directly from user parameters (convenience wrapper).
"""
function create_roofline_plot(
    params::RooflineParams,
    output_opts::OutputOptions = OutputOptions();
    show_ridges::Bool = true,
)
    config = params_to_config(params, output_opts)
    return create_roofline_plot(config, show_ridges = show_ridges)
end

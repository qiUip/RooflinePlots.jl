"""
Command-line interface for generic Roofline types.

Parses arguments in the form:
- --peak-bw-<TYPE>=<value>
- --measured-bw-<TYPE>=<value>
- --peak-flops-<TYPE>=<value>
- --measured-flops-<TYPE>=<value>
- --measured-flops=<value> (applies to all compute types)
- --measured-flops-<TYPE1>-<TYPE2>=<value> (combined measurement)
"""

"""
    validate_positive(value::Real, arg_name::String)

Validate that a numeric argument is positive (> 0).
Throws ArgumentError if validation fails.
"""
function validate_positive(value::Real, arg_name::String)
    if value <= 0
        error("$arg_name must be positive (> 0), got: $value")
    end
    return value
end

"""
    parse_commandline() -> Dict

Parse command-line arguments with generic type names.

Returns a dictionary with:
- "memory_specs": Dict{String, @NamedTuple{peak::Union{Float64,Nothing}, measured::Union{Float64,Nothing}}}
- "compute_specs": Dict{String, @NamedTuple{peak::Union{Float64,Nothing}, measured::Union{Float64,Nothing}}}
- "combined_flops": Union{Float64,Nothing} (from --measured-flops without suffix)
- "combined_flops_groups": Vector{Tuple{Vector{String}, Float64}} (from --measured-flops-type1-type2)
- Standard metadata fields
"""
function parse_commandline()
    # Show help if no arguments provided
    if isempty(ARGS)
        print_help()
        exit(0)
    end

    # Initialize result structures
    memory_specs = Dict{
        String,
        @NamedTuple{peak::Union{Float64,Nothing},measured::Union{Float64,Nothing}}
    }()
    compute_specs = Dict{
        String,
        @NamedTuple{peak::Union{Float64,Nothing},measured::Union{Float64,Nothing}}
    }()
    combined_flops = nothing
    combined_flops_groups = Tuple{Vector{String},Float64}[]

    # Metadata
    num_cores = nothing
    topology = "Topology"
    cpu_name = "CPU"
    app_name = "Application"
    output = nothing
    quiet = false
    show_plot = false
    hide_ridges = false
    save_table = false

    # Output options
    force_simple = false
    table_format = "ascii"
    mem_colors = nothing
    compute_colors = nothing
    plot_format = "svg"

    # Parse arguments manually
    i = 1
    processed = Set{Int}()  # Track which argument indices have been processed

    while i <= length(ARGS)
        arg = ARGS[i]

        if startswith(arg, "--peak-bw-")
            # Extract type and value
            rest = arg[11:end]  # Skip "--peak-bw-"
            if contains(rest, "=")
                type_name, value_str = split(rest, "=", limit = 2)
                value = parse(Float64, value_str)
                validate_positive(value, "--peak-bw-$type_name")

                if !haskey(memory_specs, type_name)
                    memory_specs[type_name] = (peak = nothing, measured = nothing)
                end
                memory_specs[type_name] =
                    (peak = value, measured = memory_specs[type_name].measured)
            end
            push!(processed, i)

        elseif startswith(arg, "--measured-bw-")
            rest = arg[15:end]  # Skip "--measured-bw-"
            if contains(rest, "=")
                type_name, value_str = split(rest, "=", limit = 2)
                value = parse(Float64, value_str)
                validate_positive(value, "--measured-bw-$type_name")

                if !haskey(memory_specs, type_name)
                    memory_specs[type_name] = (peak = nothing, measured = nothing)
                end
                memory_specs[type_name] =
                    (peak = memory_specs[type_name].peak, measured = value)
            end
            push!(processed, i)

        elseif startswith(arg, "--peak-flops-")
            rest = arg[14:end]  # Skip "--peak-flops-"
            if contains(rest, "=")
                type_name, value_str = split(rest, "=", limit = 2)
                value = parse(Float64, value_str)
                validate_positive(value, "--peak-flops-$type_name")

                if !haskey(compute_specs, type_name)
                    compute_specs[type_name] = (peak = nothing, measured = nothing)
                end
                old_entry = compute_specs[type_name]
                compute_specs[type_name] = (peak = value, measured = old_entry.measured)
            end
            push!(processed, i)

        elseif startswith(arg, "--measured-flops-")
            rest = arg[18:end]  # Skip "--measured-flops-"
            if contains(rest, "=")
                type_part, value_str = split(rest, "=", limit = 2)
                value = parse(Float64, value_str)
                validate_positive(value, "--measured-flops-$type_part")

                # Check if type_part exists as a single type first
                if haskey(compute_specs, type_part)
                    # Single type measurement (type already defined)
                    old_entry = compute_specs[type_part]
                    compute_specs[type_part] = (peak = old_entry.peak, measured = value)
                elseif contains(type_part, "-")
                    # Could be combined measurement or new type with hyphen
                    # Simple strategy: try splitting on ALL hyphens first
                    simple_parts = String.(split(type_part, "-"))

                    if length(simple_parts) >= 2 &&
                       all(p -> haskey(compute_specs, p) && !isempty(p), simple_parts)
                        # All parts exist as defined types - this is a combined measurement
                        push!(combined_flops_groups, (simple_parts, value))
                    else
                        # Not a valid combined measurement, treat as single type with hyphen in name
                        if !haskey(compute_specs, type_part)
                            compute_specs[type_part] = (peak = nothing, measured = nothing)
                        end
                        old_entry = compute_specs[type_part]
                        compute_specs[type_part] = (peak = old_entry.peak, measured = value)
                    end
                else
                    # Single type measurement without hyphen
                    if !haskey(compute_specs, type_part)
                        compute_specs[type_part] = (peak = nothing, measured = nothing)
                    end
                    old_entry = compute_specs[type_part]
                    compute_specs[type_part] = (peak = old_entry.peak, measured = value)
                end
            end
            push!(processed, i)

        elseif arg == "--measured-flops" || startswith(arg, "--measured-flops=")
            # Combined measurement for ALL types: --measured-flops=720
            value_str =
                startswith(arg, "--measured-flops=") ? split(arg, "=", limit = 2)[2] :
                ARGS[i+1]
            combined_flops = parse(Float64, value_str)
            validate_positive(combined_flops, "--measured-flops")
            if !startswith(arg, "--measured-flops=")
                push!(processed, i + 1)  # Mark next arg as processed
                i += 1  # Skip next arg
            end
            push!(processed, i)

        elseif arg == "--num-cores" || startswith(arg, "--num-cores=")
            value_str =
                startswith(arg, "--num-cores=") ? split(arg, "=", limit = 2)[2] : ARGS[i+1]
            num_cores = parse(Int, value_str)
            validate_positive(num_cores, "--num-cores")
            if !startswith(arg, "--num-cores=")
                push!(processed, i + 1)
                i += 1
            end
            push!(processed, i)

        elseif arg == "--topology" || startswith(arg, "--topology=")
            value_str =
                startswith(arg, "--topology=") ? split(arg, "=", limit = 2)[2] : ARGS[i+1]
            topology = value_str
            if !startswith(arg, "--topology=")
                push!(processed, i + 1)
                i += 1
            end
            push!(processed, i)

        elseif arg == "--cpu-name" || startswith(arg, "--cpu-name=")
            value_str =
                startswith(arg, "--cpu-name=") ? split(arg, "=", limit = 2)[2] : ARGS[i+1]
            cpu_name = value_str
            if !startswith(arg, "--cpu-name=")
                push!(processed, i + 1)
                i += 1
            end
            push!(processed, i)

        elseif arg == "--app-name" || startswith(arg, "--app-name=")
            value_str =
                startswith(arg, "--app-name=") ? split(arg, "=", limit = 2)[2] : ARGS[i+1]
            app_name = value_str
            if !startswith(arg, "--app-name=")
                push!(processed, i + 1)
                i += 1
            end
            push!(processed, i)

        elseif arg == "--output" ||
               arg == "-o" ||
               startswith(arg, "--output=") ||
               startswith(arg, "-o=")
            value_str =
                startswith(arg, "--output=") ? split(arg, "=", limit = 2)[2] :
                startswith(arg, "-o=") ? split(arg, "=", limit = 2)[2] : ARGS[i+1]
            output = value_str
            if !contains(arg, "=")
                push!(processed, i + 1)
                i += 1
            end
            push!(processed, i)

        elseif arg == "--quiet" || arg == "-q"
            quiet = true
            push!(processed, i)

        elseif arg == "--show" || arg == "-s"
            show_plot = true
            push!(processed, i)

        elseif arg == "--hide-ridges"
            hide_ridges = true
            push!(processed, i)

        elseif arg == "--force-simple"
            force_simple = true
            push!(processed, i)

        elseif arg == "--table-format" || startswith(arg, "--table-format=")
            value_str =
                startswith(arg, "--table-format=") ? split(arg, "=", limit = 2)[2] :
                ARGS[i+1]
            if value_str in ["ascii", "org", "markdown", "csv"]
                table_format = value_str
            else
                error(
                    "Unknown table format: '$value_str'. Must be one of: ascii, org, markdown, csv",
                )
            end
            if !startswith(arg, "--table-format=")
                push!(processed, i + 1)
                i += 1
            end
            push!(processed, i)

        elseif arg == "--save-table"
            save_table = true
            push!(processed, i)

        elseif arg == "--mem-colors" || startswith(arg, "--mem-colors=")
            value_str =
                startswith(arg, "--mem-colors=") ? split(arg, "=", limit = 2)[2] : ARGS[i+1]
            # Import parse_color_palette from config module
            mem_colors = RooflinePlots.parse_color_palette(value_str)
            if !startswith(arg, "--mem-colors=")
                push!(processed, i + 1)
                i += 1
            end
            push!(processed, i)

        elseif arg == "--compute-colors" || startswith(arg, "--compute-colors=")
            value_str =
                startswith(arg, "--compute-colors=") ? split(arg, "=", limit = 2)[2] :
                ARGS[i+1]
            # Import parse_color_palette from config module
            compute_colors = RooflinePlots.parse_color_palette(value_str)
            if !startswith(arg, "--compute-colors=")
                push!(processed, i + 1)
                i += 1
            end
            push!(processed, i)

        elseif arg == "--plot-format" || startswith(arg, "--plot-format=")
            value_str =
                startswith(arg, "--plot-format=") ? split(arg, "=", limit = 2)[2] :
                ARGS[i+1]
            if value_str in ["png", "pdf", "svg"]
                plot_format = value_str
            else
                error("Unknown plot format: '$value_str'. Must be one of: png, pdf, svg")
            end
            if !startswith(arg, "--plot-format=")
                push!(processed, i + 1)
                i += 1
            end
            push!(processed, i)

        elseif arg == "--help" || arg == "-h"
            print_help()
            exit(0)
        end

        i += 1
    end

    # Validate that all options were recognized
    unrecognized = String[]
    for (idx, arg) in enumerate(ARGS)
        # Check if this argument wasn't processed and looks like an option
        if idx ∉ processed && (startswith(arg, "--") || startswith(arg, "-"))
            # Skip if it's a negative number (not an option)
            if startswith(arg, "-") && !startswith(arg, "--")
                try
                    parse(Float64, arg)
                    continue  # It's a negative number, not an option
                catch
                    # Not a number, it's an unrecognized option
                end
            end
            push!(unrecognized, arg)
        end
    end

    if !isempty(unrecognized)
        error(
            "Unknown option(s): " *
            join(unrecognized, ", ") *
            "\n\nUse --help to see available options.",
        )
    end

    # Default num_cores to 1 if not specified
    if isnothing(num_cores)
        num_cores = 1
    end

    return Dict(
        # Roofline parameters
        "memory_specs" => memory_specs,
        "compute_specs" => compute_specs,
        "combined_flops" => combined_flops,
        "combined_flops_groups" => combined_flops_groups,
        "num_cores" => num_cores,
        "topology" => topology,
        "cpu_name" => cpu_name,
        "app_name" => app_name,
        # CLI control options
        "output" => output,
        "quiet" => quiet,
        "show" => show_plot,
        "hide_ridges" => hide_ridges,
        "save_table" => save_table,
        # Output options
        "force_simple" => force_simple,
        "table_format" => table_format,
        "mem_colors" => mem_colors,
        "compute_colors" => compute_colors,
        "plot_format" => plot_format,
    )
end

"""
    print_help()

Print help message for CLI.
"""
function print_help()
    println(
        """
Roofline Model Analysis - Dynamic Type Support

Usage: julia roofline.jl [OPTIONS]

Memory Bandwidth (any type name):
  --peak-bw-<TYPE>=<value>      Peak bandwidth for <TYPE> (GB/s)
  --measured-bw-<TYPE>=<value>  Measured bandwidth for <TYPE> (GB/s)

  Examples: --peak-bw-DRAM=204.8, --peak-bw-HBM=1200, --peak-bw-L3=96.42
  Note: Each --peak-bw-<TYPE> requires matching --measured-bw-<TYPE>

Compute Performance (any type name):
  --peak-flops-<TYPE>=<value>       Peak FLOPS for <TYPE> (GFLOP/s)
  --measured-flops-<TYPE>=<value>   Measured FLOPS for <TYPE> (GFLOP/s)
  --measured-flops=<value>          Combined measurement (applies to all types)
  --measured-flops-<T1>-<T2>=<val>  Combined measurement for specific types

  Examples: --peak-flops-DP=1404.9, --peak-flops-TENSOR=5000
            --measured-flops=720 (applies to all compute types)
            --measured-flops-DP-SP=720 (applies to DP and SP only)

Optional:
  --num-cores=<N>           Number of cores (default: omitted from filename)
  --topology=<str>          Topology description (default: "Topology")
  --cpu-name=<str>          CPU model name (default: "CPU")
  --app-name=<str>          Application name (default: "Application")
  --output=<fil>, -o <file> Output filename (auto-generated if not specified)
  --quiet, -q               Suppress table output
  --show, -s                Display plot window
  --hide-ridges             Hide ridge point lines
  --force-simple            Force linear mode
  --table-format=<fmt>      Table format: ascii, org, markdown, or csv (default: ascii)
  --save-table              Save table to file (.dat/.org/.md/.csv based on format)
  --plot-format=<fmt>       Plot format: png, pdf, or svg (default: png)
  --mem-colors=<colors>     Comma-separated memory color palette (color names or hex)
  --compute-colors=<colors> Comma-separated compute color palette (color names or hex)
  --help, -h                Show this help message

Color Options:
  Customize visualization colors using --mem-colors and --compute-colors.

  Formats supported:
    - Color names: red, blue, darkgreen, purple, etc.
    - Hex colors: #FF5733, #3498DB, #2ECC71, etc.

  Examples:
    --mem-colors=cyan,magenta,yellow
    --compute-colors=#FF5733,#C70039,#900C3F
    --mem-colors=blue,#3498DB,teal

  Colors are applied to peaks in sort order (memory: fastest first, compute: lowest first).
  If fewer colors than peaks, remaining peaks use default colors.

Examples:

L3+L1 with combined DP/SP measurement:
  julia roofline.jl --peak-flops-DP=1404.9 --peak-flops-SP=2809 \\
    --measured-flops=720 --peak-bw-L3=96.42 --measured-bw-L3=21.89 \\
    --peak-bw-L1=1312 --measured-bw-L1=185 --num-cores=24

Custom types (HBM, TENSOR):
  julia roofline.jl --peak-flops-TENSOR=5000 --measured-flops-TENSOR=4200 \\
    --peak-bw-HBM=1200 --measured-bw-HBM=950 --num-cores=128
""",
    )
end

"""
    get_table_file_extension(table_format::AbstractString) -> String

Get file extension for the given table format.
"""
function get_table_file_extension(table_format::AbstractString)
    if table_format == "ascii"
        return ".dat"
    elseif table_format == "org"
        return ".org"
    elseif table_format == "csv"
        return ".csv"
    else  # markdown
        return ".md"
    end
end

"""
    run_cli()

Main CLI orchestration function. Parses command-line arguments,
generates performance tables and plots, and saves output files.
"""
function run_cli()
    # Parse command-line arguments
    args = parse_commandline()

    # Create RooflineParams from parsed arguments
    params = RooflineParams(
        args["memory_specs"],
        args["compute_specs"],
        args["combined_flops"],
        args["combined_flops_groups"],
        args["num_cores"],
        args["topology"],
        args["cpu_name"],
        args["app_name"],
    )

    # Create OutputOptions from parsed arguments
    output_opts = OutputOptions(
        force_simple = args["force_simple"],
        table_format = args["table_format"],
        mem_colors = args["mem_colors"],
        compute_colors = args["compute_colors"],
        plot_format = args["plot_format"],
    )

    # Convert params to config for table and plot generation
    config = params_to_config(params, output_opts)

    # Print performance table unless --quiet flag is set
    # Also capture output if save_table is requested
    table_output = ""
    if !args["quiet"] || args["save_table"]
        if args["save_table"]
            # Capture table output to string
            table_output = mktemp() do path, io
                redirect_stdout(io) do
                    print_performance_table(config)
                end
                close(io)
                read(path, String)
            end
            # Print to console if not quiet
            if !args["quiet"]
                print(table_output)
                println()  # Add blank line after table
            end
        else
            # Just print directly if not saving
            print_performance_table(config)
            println()  # Add blank line after table
        end
    end

    # Create and save plot
    show_ridges = !args["hide_ridges"]
    plt = create_roofline_plot(config, show_ridges = show_ridges)

    output_file = if isnothing(args["output"])
        generate_output_filename(params, !config.simple_mode, output_opts.plot_format)
    else
        args["output"]
    end

    savefig(plt, output_file)

    # Save table to file if requested
    if args["save_table"]
        # Generate table filename based on plot filename
        base_name = splitext(output_file)[1]  # Remove .png extension
        table_ext = get_table_file_extension(args["table_format"])
        table_file = base_name * table_ext

        open(table_file, "w") do io
            write(io, table_output)
        end

        if args["show"]
            display(plt)
            println("\nPlot saved to: $output_file")
            println("Table saved to: $table_file")
        end
    elseif args["show"]
        display(plt)
        println("\nPlot saved to: $output_file")
    end
end

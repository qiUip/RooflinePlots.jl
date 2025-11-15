# Integration tests for RooflinePlots
# Tests end-to-end workflows: params → config → analysis → report → plot

using Plots

# Create examples directory if it doesn't exist
const TEST_EXAMPLES_DIR = joinpath(@__DIR__, "examples")
mkpath(TEST_EXAMPLES_DIR)

@testset "End-to-End: Simple DRAM+DP" begin
    # Scenario: Basic single memory level, single compute type
    memory_specs = Dict("DRAM" => (peak = 204.8, measured = 180.5))
    compute_specs = Dict("DP" => (peak = 2150.4, measured = 1245.2))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        64,
        "2S",
        "AMD EPYC 7713",
        "TestApp",
    )

    # Test: params → config conversion
    config = params_to_config(params, OutputOptions(table_format = "markdown"))
    @test length(config.compute_roofs) == 1
    @test length(config.memory_levels) == 1
    @test config.simple_mode == true

    # Test: bottleneck analysis
    # AI = 1245.2 / 180.5 ≈ 6.9
    # Ridge = 2150.4 / 204.8 ≈ 10.5
    # 6.9 < 10.5 → Memory-bound
    bottleneck = determine_bottleneck(config)
    @test occursin("Memory-bound", bottleneck)

    # Test: table generation
    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end
    @test occursin("GFLOP/s", output)
    @test occursin("GB/s", output)
    @test occursin("%", output)

    filename = "simple_dram_dp"

    # Test: table generation
    table_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".md"))
    open(table_file, "w") do io
        redirect_stdout(io) do
            print_performance_table(config)
        end
    end
    @test isfile(table_file)

    # Test: plot generation
    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot

    output_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".svg"))
    savefig(plt, output_file)
    @test isfile(output_file)
    @test filesize(output_file) > 10_000  # Reasonable plot size
end

@testset "End-to-End: Hierarchical L2+DRAM with DP+SP" begin
    # Scenario: Multiple memory levels and compute types
    memory_specs = Dict(
        "DRAM" => (peak = 96.42, measured = 21.89),
        "L2" => (peak = 1312.0, measured = 185.0),
    )
    compute_specs = Dict(
        "DP" => (peak = 1404.9, measured = 720.0),
        "SP" => (peak = 2809.0, measured = 1440.0),
    )

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        24,
        "Single NUMA (3 CCDs)",
        "Genoa @1.9GHz",
        "TestApp TestCase",
    )

    # Test: params → config conversion
    config = params_to_config(params, OutputOptions(table_format = "markdown"))

    # Test: multiple roofs and memory levels
    @test length(config.compute_roofs) == 2  # DP, SP
    @test length(config.memory_levels) == 2  # DRAM, L2
    @test config.simple_mode == false  # Hierarchical mode

    # Test: roofs are sorted by performance (ascending)
    @test config.compute_roofs[1].peak_flops < config.compute_roofs[2].peak_flops

    # Test: memory levels sorted by bandwidth (descending)
    @test config.memory_levels[1].peak_bw > config.memory_levels[2].peak_bw

    # Test: measurements created for all combinations
    @test length(config.measurements) >= 2

    filename = "hierarchical_l2_dram_dp_sp"

    # Test: table generation
    table_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".md"))
    open(table_file, "w") do io
        redirect_stdout(io) do
            print_performance_table(config)
        end
    end
    @test isfile(table_file)

    # Test: plot generation
    plt = create_roofline_plot(config)
    output_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".svg"))
    savefig(plt, output_file)
    @test isfile(output_file)
    @test filesize(output_file) > 10_000
end

@testset "End-to-End: Full Memory Hierarchy" begin
    # Scenario: L1+L2+L3+DRAM
    memory_specs = Dict(
        "DRAM" => (peak = 96.42, measured = 21.89),
        "L1" => (peak = 3200.0, measured = 890.0),
        "L2" => (peak = 1312.0, measured = 185.0),
        "L3" => (peak = 480.0, measured = 125.0),
    )
    compute_specs = Dict("DP" => (peak = 1404.9, measured = 720.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        24,
        "Single NUMA",
        "Genoa @1.9GHz",
        "TestApp",
    )

    config = params_to_config(params, OutputOptions(table_format = "markdown"))

    # Test: all 4 memory levels present
    @test length(config.memory_levels) == 4
    memory_names = [m.name for m in config.memory_levels]
    @test "L1" in memory_names
    @test "L2" in memory_names
    @test "L3" in memory_names
    @test "DRAM" in memory_names

    # Test: memory levels sorted correctly (fastest to slowest)
    bandwidths = [m.peak_bw for m in config.memory_levels]
    @test issorted(bandwidths, rev = true)

    # Test: table includes all memory levels
    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end
    @test occursin("L1", output)
    @test occursin("L2", output)
    @test occursin("L3", output)
    @test occursin("DRAM", output)

    filename = "full_hierarchy"

    # Test: table generation
    table_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".md"))
    open(table_file, "w") do io
        redirect_stdout(io) do
            print_performance_table(config)
        end
    end
    @test isfile(table_file)

    # Test: plot generation
    plt = create_roofline_plot(config)
    output_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".svg"))
    savefig(plt, output_file)
    @test isfile(output_file)
end

@testset "End-to-End: Combined DP+SP Measurement" begin
    # Scenario: DP and SP roofs with combined measurement (hardware counter reality)
    memory_specs = Dict(
        "DRAM" => (peak = 96.42, measured = 21.89),
        "L2" => (peak = 1312.0, measured = 185.0),
    )
    compute_specs = Dict(
        "DP" => (peak = 1404.9, measured = nothing),
        "SP" => (peak = 2809.0, measured = nothing),
    )

    params = RooflineParams(
        memory_specs,
        compute_specs,
        720.0,  # combined_flops
        [],
        24,
        "Single NUMA",
        "Genoa @1.9GHz",
        "TestApp Combined",
    )

    config = params_to_config(params, OutputOptions(table_format = "markdown"))

    # Test: both roofs present
    @test length(config.compute_roofs) == 2

    # Test: combined_compute_groups should include DP+SP
    @test length(config.combined_compute_groups) >= 1

    # Test: measurements use combined value
    @test all(m -> m.flops == 720.0, config.measurements)

    # Test: table shows combined measurement
    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end
    @test occursin("DP+SP", output) || occursin("Compute", output)

    filename = "combined_dp_sp"

    # Test: table generation
    table_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".md"))
    open(table_file, "w") do io
        redirect_stdout(io) do
            print_performance_table(config)
        end
    end
    @test isfile(table_file)

    # Test: plot generation
    plt = create_roofline_plot(config)
    output_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".svg"))
    savefig(plt, output_file)
    @test isfile(output_file)
end

@testset "End-to-End: Custom Type Names (HBM, TENSOR)" begin
    # Scenario: Next-gen hardware with HBM and tensor cores
    memory_specs = Dict(
        "HBM" => (peak = 1200.0, measured = 950.0),
        "L2" => (peak = 3200.0, measured = 2800.0),
    )
    compute_specs = Dict(
        "TENSOR" => (peak = 5000.0, measured = 4200.0),
        "FP32" => (peak = 2500.0, measured = 2100.0),
    )

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        128,
        "Single Package",
        "H100",
        "AI Workload",
    )

    config = params_to_config(params, OutputOptions(table_format = "markdown"))

    # Test: custom types accepted
    @test length(config.compute_roofs) == 2
    @test length(config.memory_levels) == 2

    # Test: names preserved
    compute_names = [r.name for r in config.compute_roofs]
    memory_names = [m.name for m in config.memory_levels]
    @test "TENSOR" in compute_names
    @test "FP32" in compute_names
    @test "HBM" in memory_names
    @test "L2" in memory_names

    # Test: table includes custom types
    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end
    @test occursin("TENSOR", output)
    @test occursin("HBM", output)

    filename = "custom_hbm_tensor"

    # Test: table generation
    table_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".md"))
    open(table_file, "w") do io
        redirect_stdout(io) do
            print_performance_table(config)
        end
    end
    @test isfile(table_file)

    # Test: plot generation
    plt = create_roofline_plot(config)
    output_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".svg"))
    savefig(plt, output_file)
    @test isfile(output_file)
end

@testset "End-to-End: Custom Types with Combined Groups" begin
    # Scenario: INT8 + INT16 combined (quantized inference), FP32 separate (training)
    # Use different peak values to avoid overlapping lines
    memory_specs = Dict("DDR5" => (peak = 400.0, measured = 350.0))
    compute_specs = Dict(
        "INT8" => (peak = 12000.0, measured = nothing),   # Highest - quantized ops
        "INT16" => (peak = 8000.0, measured = nothing),    # Medium - quantized ops
        "FP32" => (peak = 4000.0, measured = 3500.0),       # Lowest - fp training
    )

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [(["INT8", "INT16"], 7200.0)],  # INT8 and INT16 combined (quantized inference)
        64,
        "Single Socket",
        "Custom ASIC",
        "ML Inference",
    )

    config = params_to_config(params, OutputOptions(table_format = "markdown"))

    # Test: all compute types present
    @test length(config.compute_roofs) == 3
    compute_names = [r.name for r in config.compute_roofs]
    @test "INT8" in compute_names
    @test "INT16" in compute_names
    @test "FP32" in compute_names

    # Test: combined group exists
    @test ["INT8", "INT16"] in config.combined_compute_groups

    # Test: INT8 and INT16 measurements use combined value
    int8_meas = findfirst(m -> m.compute_name == "INT8", config.measurements)
    int16_meas = findfirst(m -> m.compute_name == "INT16", config.measurements)
    fp32_meas = findfirst(m -> m.compute_name == "FP32", config.measurements)

    @test config.measurements[int8_meas].flops == 7200.0
    @test config.measurements[int16_meas].flops == 7200.0
    @test config.measurements[fp32_meas].flops == 3500.0

    # Test: table shows combined group
    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end
    @test occursin("INT8", output)
    @test occursin("INT16", output)
    @test occursin("+", output)  # Should show INT8+INT16

    filename = "custom_combined_groups"

    # Test: table generation
    table_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".md"))
    open(table_file, "w") do io
        redirect_stdout(io) do
            print_performance_table(config)
        end
    end
    @test isfile(table_file)

    # Test: plot generation
    plt = create_roofline_plot(config)
    output_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".svg"))
    savefig(plt, output_file)
    @test isfile(output_file)
end

@testset "End-to-End: Compute-Bound Scenario" begin
    # Scenario: High AI → Compute-bound
    # AI = 500/50 = 10.0
    # Ridge = 1000/200 = 5.0
    # 10.0 > 5.0 → Compute-bound
    memory_specs = Dict("DRAM" => (peak = 200.0, measured = 50.0))
    compute_specs = Dict("DP" => (peak = 1000.0, measured = 500.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        16,
        "Test",
        "Test CPU",
        "Compute-Bound App",
    )

    config = params_to_config(params)
    bottleneck = determine_bottleneck(config)

    @test occursin("Compute-bound", bottleneck)

    # Test: table reflects compute-bound
    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end
    @test occursin("Compute-bound", output)
end

@testset "End-to-End: Memory-Bound Scenario" begin
    # Scenario: Low AI → Memory-bound
    # AI = 100/150 ≈ 0.67
    # Ridge = 1000/200 = 5.0
    # 0.67 < 5.0 → Memory-bound
    memory_specs = Dict("DRAM" => (peak = 200.0, measured = 150.0))
    compute_specs = Dict("DP" => (peak = 1000.0, measured = 100.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        16,
        "Test",
        "Test CPU",
        "Memory-Bound App",
    )

    config = params_to_config(params)

    bottleneck = determine_bottleneck(config)

    @test occursin("Memory-bound", bottleneck)

    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end
    @test occursin("Memory-bound", output)
end

@testset "End-to-End: Color Palette Assignment" begin
    # Test that colors are assigned from palettes and are distinct
    memory_specs = Dict(
        "MEM1" => (peak = 100.0, measured = 80.0),
        "MEM2" => (peak = 200.0, measured = 180.0),
        "MEM3" => (peak = 300.0, measured = 280.0),
    )
    compute_specs = Dict(
        "COMP1" => (peak = 100.0, measured = 80.0),
        "COMP2" => (peak = 200.0, measured = 180.0),
        "COMP3" => (peak = 300.0, measured = 280.0),
    )

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "Test",
        "Test CPU",
        "Color Test",
    )

    config = params_to_config(params)

    # Test: all memory levels have different colors
    memory_colors = [m.color for m in config.memory_levels]
    @test length(unique(memory_colors)) == 3

    # Test: all compute roofs have different colors
    compute_colors = [r.color for r in config.compute_roofs]
    @test length(unique(compute_colors)) == 3

    # Test: memory and compute colors are from different palettes
    # Memory colors should be from MEMORY_COLORS (cool tones)
    # Compute colors should be from COMPUTE_COLORS (warm tones)
    @test memory_colors[1] in
          [:blue, :darkgreen, :purple, :teal, :navy, :indigo, :steelblue, :darkslateblue]
    @test compute_colors[1] in
          [:red, :darkorange, :brown, :crimson, :chocolate, :firebrick, :maroon, :sienna]
end

@testset "End-to-End: Custom Colors Example" begin
    # Scenario: Custom colors with hex for memory, color names for compute
    # Memory uses hex colors: #3498DB (blue), #2ECC71 (green)
    # Compute uses color names different from defaults: orange, purple
    memory_specs = Dict(
        "DRAM" => (peak = 204.8, measured = 180.5),
        "L3" => (peak = 1200.0, measured = 950.0),
    )
    compute_specs = Dict(
        "DP" => (peak = 2150.4, measured = 1245.2),
        "SP" => (peak = 4300.0, measured = 2500.0),
    )

    # Custom color palettes (different from defaults)
    mem_colors = ["#3498DB", "#2ECC71"]  # Hex colors for memory
    compute_colors = [:orange, :purple]  # Color names for compute (different from default reds/browns)

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        64,
        "Dual Socket",
        "AMD EPYC 7713",
        "Custom Colors Example",
    )

    output_opts = OutputOptions(mem_colors = mem_colors, compute_colors = compute_colors)

    config = params_to_config(params, output_opts)

    # Test: correct number of levels and roofs
    @test length(config.memory_levels) == 2
    @test length(config.compute_roofs) == 2

    # Test: memory colors match hex values (sorted by bandwidth - L3 first, DRAM second)
    @test config.memory_levels[1].color == "#3498DB"  # L3 (fastest)
    @test config.memory_levels[2].color == "#2ECC71"  # DRAM (slower)

    # Test: compute colors match color names (sorted by performance - DP first, SP second)
    @test config.compute_roofs[1].color == :orange  # DP (lower performance)
    @test config.compute_roofs[2].color == :purple  # SP (higher performance)

    # Test: colors are different from defaults
    # Default memory colors are cool tones (blues, greens)
    # Default compute colors are warm tones (reds, oranges, browns)
    # Our custom compute colors (orange, purple) include purple which is not in default compute palette
    @test :purple ∉
          [:red, :darkorange, :brown, :crimson, :chocolate, :firebrick, :maroon, :sienna]

    filename = "custom_colors_example"

    # Test: plot generation with custom colors
    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot

    # Save SVG for color verification
    svg_file = joinpath(TEST_EXAMPLES_DIR, string(filename, ".svg"))
    savefig(plt, svg_file)
    @test isfile(svg_file)

    # Verify colors in SVG content
    svg_content = read(svg_file, String)
    svg_lower = lowercase(svg_content)

    # Check for hex colors (memory bandwidth lines)
    # SVG uses lowercase hex codes
    @test occursin("#3498db", svg_lower)  # L3 (fastest) - blue
    @test occursin("#2ecc71", svg_lower)  # DRAM (slower) - green

    # Check for named colors (compute performance lines)
    # Plots.jl converts named colors to hex codes
    @test occursin("#ffa500", svg_lower)  # orange - DP (lower performance)
    @test occursin("#800080", svg_lower)  # purple - SP (higher performance)
end

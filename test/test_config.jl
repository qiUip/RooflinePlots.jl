# Unit tests for config.jl
# Tests parameter-to-configuration conversion with analytically determined expected values

@testset "params_to_config: Basic DP + DRAM" begin
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict("DP" => (peak = 200.0, measured = 150.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    config = params_to_config(params)

    # Should have exactly 1 compute roof (DP)
    @test length(config.compute_roofs) == 1
    @test config.compute_roofs[1].name == "DP"
    @test config.compute_roofs[1].peak_flops == 200.0
    @test config.compute_roofs[1].color == :red  # First compute color

    # Should have exactly 1 memory level (DRAM)
    @test length(config.memory_levels) == 1
    @test config.memory_levels[1].name == "DRAM"
    @test config.memory_levels[1].peak_bw == 100.0
    @test config.memory_levels[1].color == :blue  # First memory color

    # Should have exactly 1 measurement (DP/DRAM)
    @test length(config.measurements) == 1
    @test config.measurements[1].compute_name == "DP"
    @test config.measurements[1].memory_name == "DRAM"
    @test config.measurements[1].flops == 150.0
    @test config.measurements[1].bandwidth == 80.0

    # Should be in simple mode (only 1 memory level)
    @test config.simple_mode == true

    # System info should be preserved
    @test config.num_cores == 8
    @test config.topology == "NUMA"
    @test config.cpu_name == "Intel Xeon"
    @test config.app_name == "TestApp"
end

@testset "params_to_config: Multiple Compute Types" begin
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict(
        "DP" => (peak = 200.0, measured = 150.0),
        "SP" => (peak = 400.0, measured = 300.0),
    )

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    config = params_to_config(params)

    # Should have 2 compute roofs: DP (200.0) and SP (400.0)
    @test length(config.compute_roofs) == 2

    # Roofs should be sorted by peak_flops ascending: DP < SP
    @test config.compute_roofs[1].peak_flops == 200.0  # DP first
    @test config.compute_roofs[2].peak_flops == 400.0  # SP second

    # Should have 2 measurements: DP/DRAM and SP/DRAM
    @test length(config.measurements) == 2
end

@testset "params_to_config: Memory Level Sorting" begin
    memory_specs = Dict(
        "DRAM" => (peak = 50.0, measured = 40.0),  # slowest
        "L3" => (peak = 200.0, measured = 180.0),  # medium
        "L1" => (peak = 800.0, measured = 750.0),   # fastest
    )
    compute_specs = Dict("DP" => (peak = 200.0, measured = 150.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    config = params_to_config(params)

    # Should have 3 memory levels
    @test length(config.memory_levels) == 3

    # Memory levels should be sorted by bandwidth descending: L1 > L3 > DRAM
    @test config.memory_levels[1].peak_bw == 800.0  # L1 first (fastest)
    @test config.memory_levels[2].peak_bw == 200.0  # L3 second
    @test config.memory_levels[3].peak_bw == 50.0   # DRAM last (slowest)
end

@testset "params_to_config: Simple Mode Determination" begin
    # Single memory level → simple_mode = true
    memory_single = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_single = Dict("DP" => (peak = 200.0, measured = 150.0))

    params_single = RooflineParams(
        memory_single,
        compute_single,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )
    config_single = params_to_config(params_single)
    @test config_single.simple_mode == true

    # Multiple memory levels → simple_mode = false
    memory_multi = Dict(
        "DRAM" => (peak = 100.0, measured = 80.0),
        "L3" => (peak = 300.0, measured = 250.0),
    )

    params_multi = RooflineParams(
        memory_multi,
        compute_single,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )
    config_multi = params_to_config(params_multi)
    @test config_multi.simple_mode == false

    # force_simple overrides → simple_mode = true
    params_forced = RooflineParams(
        memory_multi,
        compute_single,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )
    output_opts_forced = OutputOptions(force_simple = true)
    config_forced = params_to_config(params_forced, output_opts_forced)
    @test config_forced.simple_mode == true
end

@testset "params_to_config: Measurement Count with Cache Levels" begin
    # With 1 compute type (DP) and 3 memory levels (DRAM, L3, L2)
    # Should create 3 measurements: DP/DRAM, DP/L3, DP/L2
    memory_specs = Dict(
        "DRAM" => (peak = 100.0, measured = 80.0),
        "L3" => (peak = 300.0, measured = 280.0),
        "L2" => (peak = 500.0, measured = 480.0),
    )
    compute_specs = Dict("DP" => (peak = 200.0, measured = 150.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    config = params_to_config(params)

    # Should have 1 compute roof
    @test length(config.compute_roofs) == 1

    # Should have 3 memory levels
    @test length(config.memory_levels) == 3

    # Should have 3 measurements (1 compute × 3 memory)
    @test length(config.measurements) == 3
end

@testset "params_to_config: Combined Measurement Groups" begin
    # Test combined_flops (all types)
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict(
        "DP" => (peak = 200.0, measured = nothing),
        "SP" => (peak = 400.0, measured = nothing),
    )

    params = RooflineParams(
        memory_specs,
        compute_specs,
        720.0,  # combined_flops
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    config = params_to_config(params)

    # Should have 2 measurements with same flops
    @test length(config.measurements) == 2
    @test config.measurements[1].flops == 720.0
    @test config.measurements[2].flops == 720.0

    # Should have combined_compute_groups
    @test length(config.combined_compute_groups) >= 1
end

@testset "params_to_config: Specific Combined Groups" begin
    # Test combined_flops_groups (specific types)
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict(
        "DP" => (peak = 200.0, measured = nothing),
        "SP" => (peak = 400.0, measured = nothing),
        "TENSOR" => (peak = 600.0, measured = 500.0),  # Separate measurement
    )

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [(["DP", "SP"], 720.0)],  # combined_flops_groups
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    config = params_to_config(params)

    # Should have 3 measurements
    @test length(config.measurements) == 3

    # DP and SP should have same flops (720.0)
    dp_measurement = findfirst(m -> m.compute_name == "DP", config.measurements)
    sp_measurement = findfirst(m -> m.compute_name == "SP", config.measurements)
    tensor_measurement = findfirst(m -> m.compute_name == "TENSOR", config.measurements)

    @test config.measurements[dp_measurement].flops == 720.0
    @test config.measurements[sp_measurement].flops == 720.0
    @test config.measurements[tensor_measurement].flops == 500.0

    # Should have DP+SP in combined_compute_groups
    @test length(config.combined_compute_groups) == 1
    @test ["DP", "SP"] in config.combined_compute_groups
end

@testset "params_to_config: Color Assignment" begin
    # Test that colors are assigned by sort order
    memory_specs = Dict(
        "DRAM" => (peak = 50.0, measured = 40.0),
        "L3" => (peak = 200.0, measured = 180.0),
        "L1" => (peak = 800.0, measured = 750.0),
    )
    compute_specs = Dict(
        "DP" => (peak = 200.0, measured = 150.0),
        "SP" => (peak = 400.0, measured = 300.0),
        "TENSOR" => (peak = 600.0, measured = 500.0),
    )

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    config = params_to_config(params)

    # Memory colors should be from MEMORY_COLORS palette
    # Colors assigned by sort order (descending bandwidth)
    @test config.memory_levels[1].name == "L1"  # Fastest
    @test config.memory_levels[1].color == :blue  # First color

    @test config.memory_levels[2].name == "L3"
    @test config.memory_levels[2].color == :darkgreen  # Second color

    @test config.memory_levels[3].name == "DRAM"  # Slowest
    @test config.memory_levels[3].color == :purple  # Third color

    # Compute colors should be from COMPUTE_COLORS palette
    # Colors assigned by sort order (ascending flops)
    @test config.compute_roofs[1].name == "DP"  # Lowest
    @test config.compute_roofs[1].color == :red  # First color

    @test config.compute_roofs[2].name == "SP"
    @test config.compute_roofs[2].color == :darkorange  # Second color

    @test config.compute_roofs[3].name == "TENSOR"  # Highest
    @test config.compute_roofs[3].color == :brown  # Third color
end

@testset "generate_output_filename: String Transformations" begin
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict("DP" => (peak = 200.0, measured = 150.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA Socket",
        "Intel Core i7-9700K",
        "TestApp",
    )

    # Test hierarchical mode filename
    # Expected: "roofline_hierarchical_Intel_Core_i7_9700K_8cores_numa_socket.png"
    filename_hier = generate_output_filename(params, true)
    @test filename_hier ==
          "roofline_hierarchical_Intel_Core_i7_9700K_8cores_numa_socket.png"

    # Test simple mode filename
    # Expected: "roofline_Intel_Core_i7_9700K_8cores_numa_socket.png"
    filename_simple = generate_output_filename(params, false)
    @test filename_simple == "roofline_Intel_Core_i7_9700K_8cores_numa_socket.png"
end

@testset "generate_output_filename: Special Character Handling" begin
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict("DP" => (peak = 200.0, measured = 150.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        4,
        "Multi NUMA",
        "AMD-Ryzen",
        "TestApp",
    )

    filename = generate_output_filename(params, false)
    # Spaces should become underscores, hyphens should become underscores
    @test filename == "roofline_AMD_Ryzen_4cores_multi_numa.png"
end

@testset "generate_output_filename: Optional num_cores (Default)" begin
    # Test that num_cores=1 omits "_1cores" from filename
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict("DP" => (peak = 200.0, measured = 150.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        1,  # num_cores = 1 (default)
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    # Test hierarchical mode
    filename_hier = generate_output_filename(params, true)
    @test filename_hier == "roofline_hierarchical_Intel_Xeon_numa.png"
    @test !occursin("1cores", filename_hier)

    # Test simple mode
    filename_simple = generate_output_filename(params, false)
    @test filename_simple == "roofline_Intel_Xeon_numa.png"
    @test !occursin("1cores", filename_simple)
end

@testset "generate_output_filename: Optional num_cores (Specified)" begin
    # Test that num_cores > 1 includes "_Ncores" in filename
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict("DP" => (peak = 200.0, measured = 150.0))

    # Test with 2 cores
    params_2 = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        2,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )
    filename_2 = generate_output_filename(params_2, false)
    @test filename_2 == "roofline_Intel_Xeon_2cores_numa.png"

    # Test with 128 cores
    params_128 = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        128,
        "NUMA",
        "AMD EPYC",
        "TestApp",
    )
    filename_128 = generate_output_filename(params_128, false)
    @test filename_128 == "roofline_AMD_EPYC_128cores_numa.png"
end

@testset "parse_color: Color Names" begin
    # Test basic color names
    @test RooflinePlots.parse_color("red") == :red
    @test RooflinePlots.parse_color("blue") == :blue
    @test RooflinePlots.parse_color("darkgreen") == :darkgreen

    # Test case insensitivity
    @test RooflinePlots.parse_color("RED") == :red
    @test RooflinePlots.parse_color("Blue") == :blue
    @test RooflinePlots.parse_color("DarkGreen") == :darkgreen

    # Test whitespace handling
    @test RooflinePlots.parse_color("  red  ") == :red
    @test RooflinePlots.parse_color("  blue  ") == :blue
end

@testset "parse_color: Hex Colors" begin
    # Test 6-digit hex
    @test RooflinePlots.parse_color("#FF5733") == "#FF5733"
    @test RooflinePlots.parse_color("#3498DB") == "#3498DB"
    @test RooflinePlots.parse_color("#2ECC71") == "#2ECC71"

    # Test 3-digit hex
    @test RooflinePlots.parse_color("#F00") == "#F00"
    @test RooflinePlots.parse_color("#0F0") == "#0F0"
    @test RooflinePlots.parse_color("#00F") == "#00F"

    # Test lowercase hex
    @test RooflinePlots.parse_color("#ff5733") == "#ff5733"
    @test RooflinePlots.parse_color("#abc") == "#abc"

    # Test whitespace handling
    @test RooflinePlots.parse_color("  #FF5733  ") == "#FF5733"
end

@testset "parse_color: Invalid Input" begin
    # Test invalid hex format
    @test_throws ErrorException RooflinePlots.parse_color("#12")  # Too short
    @test_throws ErrorException RooflinePlots.parse_color("#12345")  # Invalid length
    @test_throws ErrorException RooflinePlots.parse_color("#GGGGGG")  # Invalid hex chars

    # Test invalid color names
    @test_throws ErrorException RooflinePlots.parse_color("")  # Empty
    @test_throws ErrorException RooflinePlots.parse_color("red-blue")  # Invalid chars
    @test_throws ErrorException RooflinePlots.parse_color("red blue")  # Spaces in name
end

@testset "parse_color_palette: Basic Parsing" begin
    # Test single color
    palette = RooflinePlots.parse_color_palette("red")
    @test length(palette) == 1
    @test palette[1] == :red

    # Test multiple colors
    palette = RooflinePlots.parse_color_palette("red,blue,green")
    @test length(palette) == 3
    @test palette[1] == :red
    @test palette[2] == :blue
    @test palette[3] == :green

    # Test mix of color names and hex
    palette = RooflinePlots.parse_color_palette("red,#FF5733,blue,#3498DB")
    @test length(palette) == 4
    @test palette[1] == :red
    @test palette[2] == "#FF5733"
    @test palette[3] == :blue
    @test palette[4] == "#3498DB"
end

@testset "parse_color_palette: Whitespace Handling" begin
    # Test whitespace around colors
    palette = RooflinePlots.parse_color_palette("red, blue, green")
    @test length(palette) == 3
    @test palette[1] == :red
    @test palette[2] == :blue
    @test palette[3] == :green

    # Test extra whitespace
    palette = RooflinePlots.parse_color_palette("  red  ,  blue  ,  green  ")
    @test length(palette) == 3
    @test palette[1] == :red
    @test palette[2] == :blue
    @test palette[3] == :green
end

@testset "parse_color_palette: Invalid Input" begin
    # Test empty palette
    @test_throws ErrorException RooflinePlots.parse_color_palette("")
    @test_throws ErrorException RooflinePlots.parse_color_palette(",,,")

    # Test invalid color in palette
    @test_throws ErrorException RooflinePlots.parse_color_palette("red,invalid-color,blue")
end

@testset "params_to_config: User-Defined Memory Colors" begin
    memory_specs = Dict(
        "DRAM" => (peak = 50.0, measured = 40.0),
        "L3" => (peak = 200.0, measured = 180.0),
        "L1" => (peak = 800.0, measured = 750.0),
    )
    compute_specs = Dict("DP" => (peak = 200.0, measured = 150.0))

    # Test with custom memory colors
    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    output_opts = OutputOptions(mem_colors = [:cyan, :magenta, :yellow])

    config = params_to_config(params, output_opts)

    # Memory levels sorted by bandwidth descending: L1 > L3 > DRAM
    @test config.memory_levels[1].name == "L1"
    @test config.memory_levels[1].color == :cyan  # First custom color

    @test config.memory_levels[2].name == "L3"
    @test config.memory_levels[2].color == :magenta  # Second custom color

    @test config.memory_levels[3].name == "DRAM"
    @test config.memory_levels[3].color == :yellow  # Third custom color
end

@testset "params_to_config: User-Defined Compute Colors" begin
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict(
        "DP" => (peak = 200.0, measured = 150.0),
        "SP" => (peak = 400.0, measured = 300.0),
        "TENSOR" => (peak = 600.0, measured = 500.0),
    )

    # Test with custom compute colors
    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    output_opts = OutputOptions(compute_colors = [:orange, :purple, :pink])

    config = params_to_config(params, output_opts)

    # Compute roofs sorted by flops ascending: DP < SP < TENSOR
    @test config.compute_roofs[1].name == "DP"
    @test config.compute_roofs[1].color == :orange  # First custom color

    @test config.compute_roofs[2].name == "SP"
    @test config.compute_roofs[2].color == :purple  # Second custom color

    @test config.compute_roofs[3].name == "TENSOR"
    @test config.compute_roofs[3].color == :pink  # Third custom color
end

@testset "params_to_config: Mixed Hex and Color Names" begin
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict(
        "DP" => (peak = 200.0, measured = 150.0),
        "SP" => (peak = 400.0, measured = 300.0),
    )

    # Test with mix of hex and color names
    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    output_opts =
        OutputOptions(mem_colors = ["#3498DB"], compute_colors = [:red, "#FF5733"])

    config = params_to_config(params, output_opts)

    @test config.memory_levels[1].color == "#3498DB"  # Hex color
    @test config.compute_roofs[1].color == :red  # Symbol color
    @test config.compute_roofs[2].color == "#FF5733"  # Hex color
end

@testset "params_to_config: Partial User Colors with Fallback" begin
    memory_specs = Dict(
        "DRAM" => (peak = 50.0, measured = 40.0),
        "L3" => (peak = 200.0, measured = 180.0),
        "L1" => (peak = 800.0, measured = 750.0),
    )
    compute_specs = Dict(
        "DP" => (peak = 200.0, measured = 150.0),
        "SP" => (peak = 400.0, measured = 300.0),
        "TENSOR" => (peak = 600.0, measured = 500.0),
    )

    # Provide only 2 memory colors for 3 memory levels
    # Provide only 1 compute color for 3 compute types
    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    output_opts = OutputOptions(mem_colors = [:cyan, :magenta], compute_colors = [:orange])

    config = params_to_config(params, output_opts)

    # First 2 memory levels should use custom colors
    @test config.memory_levels[1].color == :cyan
    @test config.memory_levels[2].color == :magenta
    # Third should fall back to default palette
    @test config.memory_levels[3].color == :purple  # Third default memory color

    # First compute roof should use custom color
    @test config.compute_roofs[1].color == :orange
    # Remaining should fall back to default palette
    @test config.compute_roofs[2].color == :darkorange  # Second default compute color
    @test config.compute_roofs[3].color == :brown  # Third default compute color
end

@testset "generate_output_filename: Plot Format Support" begin
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict("DP" => (peak = 200.0, measured = 150.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    # Test PNG format (default)
    filename_png = generate_output_filename(params, false, "png")
    @test filename_png == "roofline_Intel_Xeon_8cores_numa.png"

    # Test PDF format
    filename_pdf = generate_output_filename(params, false, "pdf")
    @test filename_pdf == "roofline_Intel_Xeon_8cores_numa.pdf"

    # Test SVG format
    filename_svg = generate_output_filename(params, false, "svg")
    @test filename_svg == "roofline_Intel_Xeon_8cores_numa.svg"

    # Test hierarchical mode with PDF
    filename_hier_pdf = generate_output_filename(params, true, "pdf")
    @test filename_hier_pdf == "roofline_hierarchical_Intel_Xeon_8cores_numa.pdf"
end

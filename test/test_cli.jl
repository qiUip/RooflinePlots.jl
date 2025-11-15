# Unit tests for cli.jl
# Tests command-line argument parsing with generic type support

@testset "parse_commandline: Basic Peak Bandwidth" begin
    # Simulate: --peak-bw-DRAM=100.0 --measured-bw-DRAM=80.0
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test haskey(args["memory_specs"], "DRAM")
        @test args["memory_specs"]["DRAM"].peak == 100.0
        @test args["memory_specs"]["DRAM"].measured == 80.0
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Measured Bandwidth" begin
    # Simulate: --peak-bw-DRAM=100.0 --measured-bw-DRAM=80.0
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test args["memory_specs"]["DRAM"].peak == 100.0
        @test args["memory_specs"]["DRAM"].measured == 80.0
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Multiple Memory Types" begin
    # Simulate: --peak-bw-DRAM=100.0 --peak-bw-L3=300.0 --peak-bw-HBM=1200.0
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-bw-L3=300.0")
        push!(ARGS, "--measured-bw-L3=280.0")
        push!(ARGS, "--peak-bw-HBM=1200.0")
        push!(ARGS, "--measured-bw-HBM=1100.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test length(args["memory_specs"]) == 3
        @test haskey(args["memory_specs"], "DRAM")
        @test haskey(args["memory_specs"], "L3")
        @test haskey(args["memory_specs"], "HBM")
        @test args["memory_specs"]["HBM"].peak == 1200.0
        @test args["memory_specs"]["HBM"].measured == 1100.0
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Basic Compute Types" begin
    # Simulate: --peak-flops-DP=200.0 --measured-flops-DP=150.0
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test haskey(args["compute_specs"], "DP")
        @test args["compute_specs"]["DP"].peak == 200.0
        @test args["compute_specs"]["DP"].measured == 150.0
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Multiple Compute Types" begin
    # Simulate: DP, SP, TENSOR
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--peak-flops-SP=400.0")
        push!(ARGS, "--peak-flops-TENSOR=5000.0")
        push!(ARGS, "--measured-flops-TENSOR=4500.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test length(args["compute_specs"]) == 3
        @test haskey(args["compute_specs"], "DP")
        @test haskey(args["compute_specs"], "SP")
        @test haskey(args["compute_specs"], "TENSOR")
        @test args["compute_specs"]["TENSOR"].peak == 5000.0
        @test args["compute_specs"]["TENSOR"].measured == 4500.0
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Combined Measurement (All Types)" begin
    # Simulate: --measured-flops=720.0 (applies to all compute types)
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--peak-flops-SP=400.0")
        push!(ARGS, "--measured-flops=720.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test args["combined_flops"] == 720.0
        @test isnothing(args["compute_specs"]["DP"].measured)
        @test isnothing(args["compute_specs"]["SP"].measured)
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Combined Measurement (Specific Types)" begin
    # Simulate: --measured-flops-DP-SP=720.0
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--peak-flops-SP=400.0")
        push!(ARGS, "--peak-flops-TENSOR=600.0")
        push!(ARGS, "--measured-flops-DP-SP=720.0")
        push!(ARGS, "--measured-flops-TENSOR=500.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test length(args["combined_flops_groups"]) == 1
        @test args["combined_flops_groups"][1][1] == ["DP", "SP"]
        @test args["combined_flops_groups"][1][2] == 720.0
        @test args["compute_specs"]["TENSOR"].measured == 500.0
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Multiple Combined Groups" begin
    # Simulate: --measured-flops-INT8-INT16=7200.0 --measured-flops-FP16-FP32=3600.0
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DDR5=400.0")
        push!(ARGS, "--measured-bw-DDR5=350.0")
        push!(ARGS, "--peak-flops-INT8=12000.0")
        push!(ARGS, "--peak-flops-INT16=8000.0")
        push!(ARGS, "--peak-flops-FP16=6000.0")
        push!(ARGS, "--peak-flops-FP32=4000.0")
        push!(ARGS, "--measured-flops-INT8-INT16=7200.0")
        push!(ARGS, "--measured-flops-FP16-FP32=3600.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test length(args["combined_flops_groups"]) == 2
        # Find the groups
        int_group = findfirst(g -> "INT8" in g[1], args["combined_flops_groups"])
        fp_group = findfirst(g -> "FP16" in g[1], args["combined_flops_groups"])

        @test !isnothing(int_group)
        @test !isnothing(fp_group)
        @test args["combined_flops_groups"][int_group][2] == 7200.0
        @test args["combined_flops_groups"][fp_group][2] == 3600.0
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Optional num_cores (Default)" begin
    # Test that num_cores defaults to 1 when not specified
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")
        # Note: --num-cores NOT specified

        args = parse_commandline()

        @test args["num_cores"] == 1
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Optional num_cores (Specified)" begin
    # Test that num_cores is set when specified
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--num-cores=64")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test args["num_cores"] == 64
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Metadata Fields" begin
    # Test topology, cpu_name, app_name
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--topology=2S NUMA")
        push!(ARGS, "--cpu-name=Intel Xeon Gold 6248R")
        push!(ARGS, "--app-name=TestApp TestCase")

        args = parse_commandline()

        @test args["topology"] == "2S NUMA"
        @test args["cpu_name"] == "Intel Xeon Gold 6248R"
        @test args["app_name"] == "TestApp TestCase"
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Flags" begin
    # Test --quiet, --show, --hide-ridges, --force-simple
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--quiet")
        push!(ARGS, "--show")
        push!(ARGS, "--hide-ridges")
        push!(ARGS, "--force-simple")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test args["quiet"] == true
        @test args["show"] == true
        @test args["hide_ridges"] == true
        @test args["force_simple"] == true
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Output File" begin
    # Test --output=filename.png
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--output=custom_plot.png")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test args["output"] == "custom_plot.png"
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Custom Type Names" begin
    # Test arbitrary type names (not just DP/SP/DRAM/L3)
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-HBM2E=1638.4")
        push!(ARGS, "--measured-bw-HBM2E=1500.0")
        push!(ARGS, "--peak-bw-DDR5=204.8")
        push!(ARGS, "--measured-bw-DDR5=180.0")
        push!(ARGS, "--peak-flops-CUDA=19500.0")
        push!(ARGS, "--peak-flops-TENSOR=312000.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test haskey(args["memory_specs"], "HBM2E")
        @test haskey(args["memory_specs"], "DDR5")
        @test haskey(args["compute_specs"], "CUDA")
        @test haskey(args["compute_specs"], "TENSOR")
        @test args["memory_specs"]["HBM2E"].peak == 1638.4
        @test args["compute_specs"]["TENSOR"].peak == 312000.0
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Hyphenated Type Names" begin
    # Test type names with hyphens (e.g., FP-32, INT-8)
    # Note: Combining hyphenated types is ambiguous, so we test individual types only
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-FP-32=4000.0")
        push!(ARGS, "--measured-flops-FP-32=3500.0")
        push!(ARGS, "--peak-flops-INT-8=12000.0")
        push!(ARGS, "--measured-flops-INT-8=11000.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test haskey(args["compute_specs"], "FP-32")
        @test args["compute_specs"]["FP-32"].peak == 4000.0
        @test args["compute_specs"]["FP-32"].measured == 3500.0
        @test haskey(args["compute_specs"], "INT-8")
        @test args["compute_specs"]["INT-8"].peak == 12000.0
        @test args["compute_specs"]["INT-8"].measured == 11000.0
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "get_table_file_extension: All Formats" begin
    @test get_table_file_extension("ascii") == ".dat"
    @test get_table_file_extension("org") == ".org"
    @test get_table_file_extension("markdown") == ".md"
    @test get_table_file_extension("csv") == ".csv"
end

@testset "run_cli: End-to-End Simple Case" begin
    # Test run_cli() with minimal arguments
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")
        push!(ARGS, "--quiet")  # Suppress console output
        push!(ARGS, "--output=test_cli_output.png")

        # Run CLI
        run_cli()

        # Verify output file was created
        @test isfile("test_cli_output.png")
        @test filesize("test_cli_output.png") > 1000  # Reasonable plot size

        # Cleanup
        rm("test_cli_output.png", force = true)
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "run_cli: With Table Save" begin
    # Test run_cli() with --save-table
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")
        push!(ARGS, "--quiet")
        push!(ARGS, "--output=test_cli_with_table.png")
        push!(ARGS, "--save-table")
        push!(ARGS, "--table-format=markdown")

        # Run CLI
        run_cli()

        # Verify both files were created
        @test isfile("test_cli_with_table.png")
        @test isfile("test_cli_with_table.md")
        @test filesize("test_cli_with_table.png") > 1000
        @test filesize("test_cli_with_table.md") > 100  # Table should have content

        # Cleanup
        rm("test_cli_with_table.png", force = true)
        rm("test_cli_with_table.md", force = true)
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Negative Values" begin
    # Test that negative values are rejected for bandwidth
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=-100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")

        @test_throws ErrorException parse_commandline()
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Zero Values" begin
    # Test that zero values are rejected for FLOPS
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=0.0")

        @test_throws ErrorException parse_commandline()
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Negative Measured FLOPS" begin
    # Test that negative measured-flops is rejected
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops=-50.0")

        @test_throws ErrorException parse_commandline()
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Negative num-cores" begin
    # Test that negative num-cores is rejected
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--num-cores=-5")

        @test_throws ErrorException parse_commandline()
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Zero num-cores" begin
    # Test that zero num-cores is rejected
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--num-cores=0")

        @test_throws ErrorException parse_commandline()
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Memory Colors - Color Names" begin
    # Test --mem-colors with color names
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-bw-L3=300.0")
        push!(ARGS, "--measured-bw-L3=280.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--mem-colors=cyan,magenta,yellow")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test !isnothing(args["mem_colors"])
        @test length(args["mem_colors"]) == 3
        @test args["mem_colors"][1] == :cyan
        @test args["mem_colors"][2] == :magenta
        @test args["mem_colors"][3] == :yellow
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Memory Colors - Hex" begin
    # Test --mem-colors with hex colors
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--mem-colors=#FF5733,#3498DB")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test !isnothing(args["mem_colors"])
        @test length(args["mem_colors"]) == 2
        @test args["mem_colors"][1] == "#FF5733"
        @test args["mem_colors"][2] == "#3498DB"
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Compute Colors - Color Names" begin
    # Test --compute-colors with color names
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--peak-flops-SP=400.0")
        push!(ARGS, "--measured-flops-SP=300.0")
        push!(ARGS, "--compute-colors=orange,purple")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test !isnothing(args["compute_colors"])
        @test length(args["compute_colors"]) == 2
        @test args["compute_colors"][1] == :orange
        @test args["compute_colors"][2] == :purple
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Compute Colors - Mixed Formats" begin
    # Test --compute-colors with mix of color names and hex
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--compute-colors=red,#FF5733,blue")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test !isnothing(args["compute_colors"])
        @test length(args["compute_colors"]) == 3
        @test args["compute_colors"][1] == :red
        @test args["compute_colors"][2] == "#FF5733"
        @test args["compute_colors"][3] == :blue
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Both Memory and Compute Colors" begin
    # Test --mem-colors and --compute-colors together
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--mem-colors=cyan,magenta")
        push!(ARGS, "--compute-colors=orange,purple")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        args = parse_commandline()

        @test !isnothing(args["mem_colors"])
        @test !isnothing(args["compute_colors"])
        @test args["mem_colors"][1] == :cyan
        @test args["compute_colors"][1] == :orange
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Color Validation - Invalid Hex" begin
    # Test that invalid hex colors are rejected
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--mem-colors=#GGGGGG")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        @test_throws ErrorException parse_commandline()
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Color Validation - Invalid Color Name" begin
    # Test that invalid color names are rejected
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--compute-colors=red-blue")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")

        @test_throws ErrorException parse_commandline()
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "run_cli: End-to-End with Custom Colors" begin
    # Test run_cli() with custom colors
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-bw-L3=300.0")
        push!(ARGS, "--measured-bw-L3=280.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--measured-flops-DP=150.0")
        push!(ARGS, "--peak-flops-SP=400.0")
        push!(ARGS, "--measured-flops-SP=300.0")
        push!(ARGS, "--mem-colors=cyan,magenta")
        push!(ARGS, "--compute-colors=orange,purple")
        push!(ARGS, "--topology=Test")
        push!(ARGS, "--cpu-name=TestCPU")
        push!(ARGS, "--app-name=TestApp")
        push!(ARGS, "--quiet")
        push!(ARGS, "--output=test_cli_colors_output.png")

        # Run CLI
        run_cli()

        # Verify output file was created
        @test isfile("test_cli_colors_output.png")
        @test filesize("test_cli_colors_output.png") > 1000

        # Cleanup
        rm("test_cli_colors_output.png", force = true)
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Unknown Option (typo in name)" begin
    # Test that unknown option names are rejected
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--table-style=pdf")  # Wrong: should be --table-format

        err = @test_throws ErrorException parse_commandline()
        @test occursin("Unknown option", err.value.msg)
        @test occursin("--table-style", err.value.msg)
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Unknown Option (wrong format flag)" begin
    # Test that typo in plot-format option name is caught
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--format-plot=org")  # Wrong: should be --plot-format

        err = @test_throws ErrorException parse_commandline()
        @test occursin("Unknown option", err.value.msg)
        @test occursin("--format-plot", err.value.msg)
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Multiple Unknown Options" begin
    # Test that multiple unknown options are all reported
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--table-style=pdf")
        push!(ARGS, "--format-plot=svg")
        push!(ARGS, "--unknown-flag")

        err = @test_throws ErrorException parse_commandline()
        @test occursin("Unknown option", err.value.msg)
        # Should mention at least one of the unknown options
        @test occursin("--table-style", err.value.msg) ||
              occursin("--format-plot", err.value.msg) ||
              occursin("--unknown-flag", err.value.msg)
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Invalid table-format value" begin
    # Test that invalid table format values are rejected
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--table-format=docx")  # Invalid: should be ascii, org, markdown, or csv

        err = @test_throws ErrorException parse_commandline()
        @test occursin("Unknown table format", err.value.msg)
        @test occursin("docx", err.value.msg)
        @test occursin("ascii", err.value.msg)  # Should show valid options
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Invalid table-format value (pdf)" begin
    # Test another invalid table format
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--table-format=pdf")  # Invalid

        err = @test_throws ErrorException parse_commandline()
        @test occursin("Unknown table format", err.value.msg)
        @test occursin("pdf", err.value.msg)
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Invalid plot-format value (jpg)" begin
    # Test that invalid plot format values are rejected
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--plot-format=jpg")  # Invalid: should be png, pdf, or svg

        err = @test_throws ErrorException parse_commandline()
        @test occursin("Unknown plot format", err.value.msg)
        @test occursin("jpg", err.value.msg)
        @test occursin("png", err.value.msg)  # Should show valid options
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Invalid plot-format value (gif)" begin
    # Test another invalid plot format
    original_args = copy(ARGS)
    try
        empty!(ARGS)
        push!(ARGS, "--peak-bw-DRAM=100.0")
        push!(ARGS, "--measured-bw-DRAM=80.0")
        push!(ARGS, "--peak-flops-DP=200.0")
        push!(ARGS, "--plot-format=gif")  # Invalid

        err = @test_throws ErrorException parse_commandline()
        @test occursin("Unknown plot format", err.value.msg)
        @test occursin("gif", err.value.msg)
    finally
        empty!(ARGS)
        append!(ARGS, original_args)
    end
end

@testset "parse_commandline: Validation - Valid plot-format values" begin
    # Test that all valid plot formats are accepted
    original_args = copy(ARGS)

    for format in ["png", "pdf", "svg"]
        try
            empty!(ARGS)
            push!(ARGS, "--peak-bw-DRAM=100.0")
            push!(ARGS, "--measured-bw-DRAM=80.0")
            push!(ARGS, "--peak-flops-DP=200.0")
            push!(ARGS, "--plot-format=$format")
            push!(ARGS, "--topology=Test")
            push!(ARGS, "--cpu-name=TestCPU")
            push!(ARGS, "--app-name=TestApp")

            args = parse_commandline()
            @test args["plot_format"] == format
        finally
            empty!(ARGS)
        end
    end

    append!(ARGS, original_args)
end

@testset "parse_commandline: Validation - Valid table-format values" begin
    # Test that all valid table formats are accepted
    original_args = copy(ARGS)

    for format in ["ascii", "org", "markdown", "csv"]
        try
            empty!(ARGS)
            push!(ARGS, "--peak-bw-DRAM=100.0")
            push!(ARGS, "--measured-bw-DRAM=80.0")
            push!(ARGS, "--peak-flops-DP=200.0")
            push!(ARGS, "--table-format=$format")
            push!(ARGS, "--topology=Test")
            push!(ARGS, "--cpu-name=TestCPU")
            push!(ARGS, "--app-name=TestApp")

            args = parse_commandline()
            @test args["table_format"] == format
        finally
            empty!(ARGS)
        end
    end

    append!(ARGS, original_args)
end

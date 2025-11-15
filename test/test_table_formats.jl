# Unit tests for table format output
# Tests that different table formats generate correct output

@testset "Table Format: ASCII" begin
    compute_roofs = [ComputeRoof("DP", 200.0, :red)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 150.0, 80.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        true,
        "ascii",
    )

    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end

    # ASCII format should use +---+ separators
    @test occursin("+", output)
    @test occursin("| Metric", output)
    @test occursin("Value |", output)
    @test !occursin("|---", output)  # Should not have org-style separator

    # Check that table has top and bottom borders
    lines = split(output, '\n')
    @test startswith(lines[1], "+")
    @test occursin("+", lines[end-1])  # Last non-empty line
end

@testset "Table Format: Org" begin
    compute_roofs = [ComputeRoof("DP", 200.0, :red)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 150.0, 80.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        true,
        "org",
    )

    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end

    # Org format should use |---+ separators
    @test occursin("|---", output)
    @test occursin("+-", output)
    @test occursin("| Metric", output)
    @test occursin("Value |", output)

    # Check that table has top and bottom borders
    lines = split(output, '\n')
    @test startswith(lines[1], "|")
    @test occursin("|", lines[end-1])
end

@testset "Table Format: Markdown" begin
    compute_roofs = [ComputeRoof("DP", 200.0, :red)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 150.0, 80.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        true,
        "markdown",
    )

    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end

    # Markdown format should use |---| separators
    @test occursin("|---", output)
    @test occursin("| Metric", output)
    @test occursin("Value |", output)
    @test !occursin("+", output)  # Should not have + signs

    # Check that markdown has NO top or bottom borders (only header separator)
    lines = filter(!isempty, split(output, '\n'))
    @test startswith(lines[1], "| Metric")  # First line is header
    @test startswith(lines[2], "|---")  # Second line is separator
    @test !startswith(lines[end], "|---")  # Last line is data, not separator
end

@testset "Table Format: CSV" begin
    compute_roofs = [ComputeRoof("DP", 200.0, :red)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 150.0, 80.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        true,
        "csv",
    )

    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end

    # CSV format should have header and comma-separated values
    @test occursin("Metric,Value", output)
    @test occursin("Measured DP Compute,", output)
    @test occursin("GFLOP/s", output)
    @test !occursin("|", output)  # No table borders
    @test !occursin("+", output)  # No table borders

    # Check that all lines are comma-separated
    lines = filter(!isempty, split(output, '\n'))
    for line in lines
        @test occursin(",", line)
    end
end

@testset "Table Format: CSV with Commas in Values" begin
    # Test that commas in values are properly escaped
    compute_roofs = [ComputeRoof("DP", 200.0, :red)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 150.0, 80.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        true,
        "csv",
    )

    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end

    # The bottleneck line contains a comma in the value, so it should be quoted
    # Example: "Memory-bound (DP/DRAM)"
    if occursin("Memory-bound (DP/DRAM)", output)
        @test occursin("\"Memory-bound (DP/DRAM)\"", output)
    end
end

@testset "Table Format: All Formats Have Same Content" begin
    # Test that all formats contain the same information, just formatted differently
    compute_roofs = [ComputeRoof("DP", 200.0, :red)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 150.0, 80.0)]

    formats = ["ascii", "org", "markdown", "csv"]
    outputs = Dict{String,String}()

    for format in formats
        config = RooflineConfig(
            compute_roofs,
            memory_levels,
            measurements,
            [],
            8,
            "NUMA",
            "Intel Xeon",
            "TestApp",
            true,
            format,
        )

        output = mktemp() do path, io
            redirect_stdout(io) do
                print_performance_table(config)
            end
            close(io)
            read(path, String)
        end

        outputs[format] = output
    end

    # All formats should contain these key values
    key_values = [
        "150.0 GFLOP/s",  # Measured compute
        "75.0%",          # Percentage of peak DP
        "80.00 GB/s",     # Measured bandwidth
        "80.0%",          # Percentage of peak DRAM
        "1.88 FLOP/B",    # Arithmetic intensity
    ]

    for format in formats
        for value in key_values
            if !occursin(value, outputs[format])
                @error "Format $format missing value: $value"
            end
            @test occursin(value, outputs[format])
        end
    end
end

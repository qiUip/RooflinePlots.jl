# Unit tests for reporting.jl
# Tests formatted output with pre-calculated performance metrics

@testset "print_performance_table: Basic Output" begin
    # Analytical calculations:
    # measured_flops = 150.0, peak_flops = 200.0 → 75% of peak
    # measured_bw = 80.0, peak_bw = 100.0 → 80% of peak
    # AI = 150.0/80.0 = 1.875 FLOP/Byte
    # ridge_AI = 200.0/100.0 = 2.0 → Memory-bound (1.875 < 2.0)

    compute_roofs = [ComputeRoof("DP", 200.0, :orange)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 150.0, 80.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],  # combined_compute_groups
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        true,
        "ascii",
    )

    # Capture output using redirect_stdout
    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end

    # Verify key values appear in output
    @test occursin("150.0 GFLOP/s", output)  # Measured compute
    @test occursin("75.0%", output)          # 150/200 = 75% of peak DP
    @test occursin("80.00 GB/s", output)     # Measured bandwidth
    @test occursin("80.0%", output)          # 80/100 = 80% of peak DRAM
    @test occursin("1.88 FLOP/B", output)    # AI = 150/80 = 1.875
    @test occursin("Memory-bound (DP/DRAM)", output)  # Bottleneck
end

@testset "print_performance_table: Multiple Memory Levels" begin
    # Analytical calculations:
    # DP: measured = 180.0, peak = 200.0 → 90% of peak
    # DRAM: measured = 60.0, peak = 100.0 → 60% of peak
    # L3: measured = 280.0, peak = 300.0 → 93.33% of peak
    # AI_dram = 180/60 = 3.0 FLOP/Byte
    # AI_l3 = 180/280 ≈ 0.643 FLOP/Byte

    compute_roofs = [ComputeRoof("DP", 200.0, :orange)]
    memory_levels = [MemoryLevel("L3", 300.0, :teal), MemoryLevel("DRAM", 100.0, :blue)]
    measurements =
        [Measurement("DP", "DRAM", 180.0, 60.0), Measurement("DP", "L3", 180.0, 280.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],  # combined_compute_groups
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        false,
        "ascii",
    )

    output = mktemp() do path, io
        redirect_stdout(io) do
            print_performance_table(config)
        end
        close(io)
        read(path, String)
    end

    # Verify DRAM metrics
    @test occursin("60.00 GB/s", output)    # DRAM bandwidth
    @test occursin("60.0%", output)         # DRAM percentage

    # Verify L3 metrics
    @test occursin("280.00 GB/s", output)   # L3 bandwidth
    @test occursin("93.3%", output)         # L3 percentage (280/300)

    # Verify arithmetic intensities
    @test occursin("3.00 FLOP/B", output)   # AI for DRAM
    @test occursin("0.64 FLOP/B", output)   # AI for L3
end

@testset "print_performance_table: Percentage Calculations" begin
    # Test with specific values for easy percentage calculation
    # measured = 50.0, peak = 200.0 → exactly 25%

    compute_roofs = [ComputeRoof("DP", 200.0, :orange)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 50.0, 50.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],  # combined_compute_groups
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

    # Verify exact percentage
    @test occursin("25.0%", output)  # 50/200 = 25% of peak DP
    @test occursin("50.0%", output)  # 50/100 = 50% of peak DRAM
end

@testset "print_performance_table: No Measurements" begin
    compute_roofs = [ComputeRoof("DP", 200.0, :orange)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = Measurement[]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],  # combined_compute_groups
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

    # Should output message about no measurements
    @test occursin("No measurements", output)
end

@testset "print_performance_table: Table Structure" begin
    compute_roofs = [ComputeRoof("DP", 200.0, :orange)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 150.0, 80.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],  # combined_compute_groups
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

    # Verify table structure elements
    @test occursin("Metric", output)
    @test occursin("Value", output)
    @test occursin("|", output)  # Table borders
    @test occursin("-", output)  # Table lines
end

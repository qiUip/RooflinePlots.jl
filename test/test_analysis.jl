# Unit tests for analysis.jl
# Tests bottleneck detection with hand-calculated arithmetic intensity and ridge points

@testset "determine_bottleneck: Memory-Bound (DRAM)" begin
    # Analytical calculation:
    # peak_flops = 200 GFLOP/s, peak_bw = 100 GB/s
    # ridge_AI = 200/100 = 2.0 FLOP/Byte
    # measured: flops = 80 GFLOP/s, bandwidth = 80 GB/s
    # AI = 80/80 = 1.0 FLOP/Byte
    # Since 1.0 < 2.0 → Memory-bound at DRAM

    compute_roofs = [ComputeRoof("DP", 200.0, :orange)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 80.0, 80.0)]

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

    bottleneck = determine_bottleneck(config)
    @test bottleneck == "Memory-bound (DP/DRAM)"
end

@testset "determine_bottleneck: Compute-Bound" begin
    # Analytical calculation:
    # peak_flops = 200 GFLOP/s, peak_bw = 100 GB/s
    # ridge_AI = 200/100 = 2.0 FLOP/Byte
    # measured: flops = 150 GFLOP/s, bandwidth = 40 GB/s
    # AI = 150/40 = 3.75 FLOP/Byte
    # Since 3.75 > 2.0 → Compute-bound

    compute_roofs = [ComputeRoof("DP", 200.0, :orange)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 150.0, 40.0)]

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

    bottleneck = determine_bottleneck(config)
    @test bottleneck == "Compute-bound"
end

@testset "determine_bottleneck: Memory Priority (DRAM over L3)" begin
    # Analytical calculation for both memory levels:
    # DRAM: ridge_AI = 200/50 = 4.0 FLOP/Byte
    # L3: ridge_AI = 200/300 = 0.667 FLOP/Byte
    # measured: flops = 100 GFLOP/s, bandwidth_dram = 40 GB/s, bandwidth_l3 = 250 GB/s
    # AI_dram = 100/40 = 2.5 FLOP/Byte < 4.0 → Memory-bound at DRAM
    # AI_l3 = 100/250 = 0.4 FLOP/Byte < 0.667 → Memory-bound at L3
    # Priority: DRAM > L3, so should report DRAM

    compute_roofs = [ComputeRoof("DP", 200.0, :orange)]
    memory_levels = [MemoryLevel("L3", 300.0, :teal), MemoryLevel("DRAM", 50.0, :blue)]
    measurements =
        [Measurement("DP", "DRAM", 100.0, 40.0), Measurement("DP", "L3", 100.0, 250.0)]

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

    bottleneck = determine_bottleneck(config)
    @test bottleneck == "Memory-bound (DP/DRAM)"
end

@testset "determine_bottleneck: L3 Bound (DRAM Compute-Bound)" begin
    # Analytical calculation:
    # DRAM: ridge_AI = 200/50 = 4.0 FLOP/Byte
    # L3: ridge_AI = 200/300 = 0.667 FLOP/Byte
    # measured: flops = 150 GFLOP/s, bandwidth_dram = 30 GB/s, bandwidth_l3 = 200 GB/s
    # AI_dram = 150/30 = 5.0 FLOP/Byte > 4.0 → Compute-bound for DRAM
    # AI_l3 = 150/200 = 0.75 FLOP/Byte > 0.667 → Compute-bound for L3
    # Both are compute-bound → should report "Compute-bound"

    compute_roofs = [ComputeRoof("DP", 200.0, :orange)]
    memory_levels = [MemoryLevel("L3", 300.0, :teal), MemoryLevel("DRAM", 50.0, :blue)]
    measurements =
        [Measurement("DP", "DRAM", 150.0, 30.0), Measurement("DP", "L3", 150.0, 200.0)]

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

    bottleneck = determine_bottleneck(config)
    @test bottleneck == "Compute-bound"
end

@testset "determine_bottleneck: At Ridge Point Boundary" begin
    # Analytical calculation:
    # peak_flops = 100 GFLOP/s, peak_bw = 50 GB/s
    # ridge_AI = 100/50 = 2.0 FLOP/Byte
    # measured: flops = 80 GFLOP/s, bandwidth = 40 GB/s
    # AI = 80/40 = 2.0 FLOP/Byte (exactly at ridge point)
    # At ridge point (equal), neither memory nor compute bound

    compute_roofs = [ComputeRoof("DP", 100.0, :orange)]
    memory_levels = [MemoryLevel("DRAM", 50.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 80.0, 40.0)]

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

    bottleneck = determine_bottleneck(config)
    # When exactly at ridge point, should report "Unknown"
    @test bottleneck == "Unknown"
end

@testset "determine_bottleneck: No Measurements" begin
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

    bottleneck = determine_bottleneck(config)
    @test bottleneck == "Unknown (no measurements)"
end

@testset "determine_bottleneck: L1 Priority" begin
    # Test that L1 bound is detected when other levels are compute-bound
    # L1: ridge_AI = 200/800 = 0.25 FLOP/Byte
    # measured: flops = 150, bandwidth_l1 = 700
    # AI_l1 = 150/700 ≈ 0.214 FLOP/Byte < 0.25 → Memory-bound at L1

    compute_roofs = [ComputeRoof("DP", 200.0, :orange)]
    memory_levels = [MemoryLevel("L1", 800.0, :cyan), MemoryLevel("DRAM", 100.0, :blue)]
    measurements =
        [Measurement("DP", "L1", 150.0, 700.0), Measurement("DP", "DRAM", 150.0, 50.0)]

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

    # DRAM: AI = 150/50 = 3.0, ridge = 200/100 = 2.0 → compute-bound
    # L1: AI = 150/700 ≈ 0.214, ridge = 200/800 = 0.25 → memory-bound
    # No DRAM bound, so should report L1
    bottleneck = determine_bottleneck(config)
    @test bottleneck == "Memory-bound (DP/L1)"
end

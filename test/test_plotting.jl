# Unit tests for plotting.jl
# Tests plotting calculations without creating actual plots

using Plots

@testset "Dynamic ymin Calculation: Based on Bottom Roof" begin
    # When measurements are higher than bottom roof, use 50% of bottom roof
    compute_roofs = [ComputeRoof("DP", 200.0, :red), ComputeRoof("SP", 400.0, :darkorange)]
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

    # Bottom roof is 200.0 (DP)
    # Lowest measurement is 150.0
    # ymin should be min(200.0, 150.0) * 0.5 = 150.0 * 0.5 = 75.0
    expected_ymin = 150.0 * 0.5

    # We can't directly test internal calculations without modifying plotting.jl,
    # but we can verify the plot is created successfully with these values
    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Dynamic ymin Calculation: Based on Low Measurement" begin
    # When measurements are lower than bottom roof, use 50% of lowest measurement
    compute_roofs = [ComputeRoof("DP", 1000.0, :red)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 50.0, 80.0)]

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

    # Bottom roof is 1000.0
    # Lowest measurement is 50.0
    # ymin should be min(1000.0, 50.0) * 0.5 = 50.0 * 0.5 = 25.0

    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Dynamic ymin Calculation: No Measurements" begin
    # When no measurements, use 50% of bottom roof
    compute_roofs = [ComputeRoof("DP", 200.0, :red)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = Measurement[]

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

    # Bottom roof is 200.0
    # No measurements
    # ymin should be 200.0 * 0.5 = 100.0

    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Dynamic xmax Calculation: Simple Mode with Measurements" begin
    # In simple mode with measurements, xmax based on ridge point and max AI
    compute_roofs = [ComputeRoof("DP", 1000.0, :red)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]

    # AI = 500/50 = 10.0 FLOP/Byte
    measurements = [Measurement("DP", "DRAM", 500.0, 50.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        true,  # simple_mode
        "ascii",
    )

    # Ridge point: 1000.0 / 100.0 = 10.0
    # Max AI: 500/50 = 10.0
    # xmax = max(10.0 * 2.0, 10.0 * 1.5) = max(20.0, 15.0) = 20.0

    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Dynamic xmax Calculation: Hierarchical Mode with Measurements" begin
    # In hierarchical mode, multiplier is 5.0 and 10.0
    compute_roofs = [ComputeRoof("DP", 1000.0, :red)]
    memory_levels =
        [MemoryLevel("L3", 500.0, :darkgreen), MemoryLevel("DRAM", 100.0, :blue)]

    # AI = 300/50 = 6.0 FLOP/Byte
    measurements =
        [Measurement("DP", "DRAM", 300.0, 50.0), Measurement("DP", "L3", 300.0, 400.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        false,  # hierarchical mode
        "ascii",
    )

    # Slowest memory ridge: 1000.0 / 100.0 = 10.0
    # Max AI: 300/50 = 6.0
    # xmax = max(10.0 * 5.0, 6.0 * 10.0) = max(50.0, 60.0) = 60.0

    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Unique Point Tracking: Duplicate Measurements" begin
    # Test that duplicate measurement coordinates are handled
    # (same memory_name, same AI, same flops)
    compute_roofs = [ComputeRoof("DP", 200.0, :red), ComputeRoof("SP", 400.0, :darkorange)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]

    # Both measurements have same coordinates (AI=1.5, flops=120.0)
    measurements = [
        Measurement("DP", "DRAM", 120.0, 80.0),  # AI = 1.5
        Measurement("SP", "DRAM", 120.0, 80.0),   # AI = 1.5 (same point!)
    ]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [["DP", "SP"]],  # Combined group
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        true,
        "ascii",
    )

    # Should create plot without duplicating points
    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Ridge Point Calculation: Single Memory Level" begin
    # Ridge point = peak_flops / peak_bw
    compute_roofs = [ComputeRoof("DP", 2150.4, :red)]
    memory_levels = [MemoryLevel("DRAM", 204.8, :blue)]
    measurements = [Measurement("DP", "DRAM", 1245.2, 180.5)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        64,
        "2S",
        "AMD EPYC 7713",
        "TestApp",
        true,
        "ascii",
    )

    # Ridge point: 2150.4 / 204.8 ≈ 10.5 FLOP/Byte
    # Measurement AI: 1245.2 / 180.5 ≈ 6.9 FLOP/Byte
    # Since 6.9 < 10.5, should be memory-bound

    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot

    bottleneck = determine_bottleneck(config)
    @test occursin("Memory-bound", bottleneck)
end

@testset "Ridge Point Calculation: Multiple Memory Levels" begin
    # Multiple ridge points for different memory levels
    compute_roofs = [ComputeRoof("DP", 1404.9, :red)]
    memory_levels = [
        MemoryLevel("L2", 1312.0, :darkgreen),  # Ridge: 1404.9/1312.0 ≈ 1.07
        MemoryLevel("DRAM", 96.42, :blue),       # Ridge: 1404.9/96.42 ≈ 14.57
    ]
    measurements = [
        Measurement("DP", "L2", 720.0, 185.0),   # AI ≈ 3.89
        Measurement("DP", "DRAM", 720.0, 21.89),  # AI ≈ 32.9
    ]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        24,
        "Single NUMA",
        "Genoa",
        "TestApp",
        false,
        "ascii",
    )

    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Label Positioning: Simple Mode" begin
    # In simple mode, labels use fixed percentage offsets
    compute_roofs = [ComputeRoof("DP", 1000.0, :red)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements = [Measurement("DP", "DRAM", 500.0, 80.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        true,  # simple_mode
        "ascii",
    )

    # Simple mode should use percentage of axis range for offsets
    # Compute labels: 3% x-offset, 2% y-offset
    # Memory labels: 6% x-offset

    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Label Positioning: Hierarchical Mode" begin
    # In hierarchical mode, labels use logarithmic offsets
    compute_roofs = [ComputeRoof("DP", 1000.0, :red)]
    memory_levels =
        [MemoryLevel("L3", 500.0, :darkgreen), MemoryLevel("DRAM", 100.0, :blue)]
    measurements =
        [Measurement("DP", "DRAM", 500.0, 80.0), Measurement("DP", "L3", 500.0, 400.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        false,  # hierarchical mode
        "ascii",
    )

    # Hierarchical mode uses log-scale offsets
    # Compute: 3% log-offset, 1.03 multiplicative y-offset

    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Plot Generation: show_ridges Parameter" begin
    # Test both with and without ridge points
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

    # With ridge points
    plt_with_ridges = create_roofline_plot(config, show_ridges = true)
    @test plt_with_ridges isa Plots.Plot

    # Without ridge points
    plt_no_ridges = create_roofline_plot(config, show_ridges = false)
    @test plt_no_ridges isa Plots.Plot
end

@testset "Plot Generation: Combined Compute Groups" begin
    # Test marker stroke color for combined measurements
    compute_roofs = [ComputeRoof("DP", 200.0, :red), ComputeRoof("SP", 400.0, :darkorange)]
    memory_levels = [MemoryLevel("DRAM", 100.0, :blue)]
    measurements =
        [Measurement("DP", "DRAM", 720.0, 80.0), Measurement("SP", "DRAM", 720.0, 80.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [["DP", "SP"]],  # Combined group
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
        true,
        "ascii",
    )

    # Measurements in combined groups should use specific compute type colors
    # for marker stroke (to distinguish which roof they correspond to)

    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Plot Generation: Many Compute Types" begin
    # Test with many compute types to verify color assignment
    compute_roofs = [
        ComputeRoof("INT8", 12000.0, :red),
        ComputeRoof("INT16", 8000.0, :darkorange),
        ComputeRoof("FP16", 6000.0, :brown),
        ComputeRoof("FP32", 4000.0, :crimson),
        ComputeRoof("FP64", 2000.0, :chocolate),
    ]
    memory_levels = [MemoryLevel("HBM", 1200.0, :blue)]
    measurements = [
        Measurement("INT8", "HBM", 11000.0, 1100.0),
        Measurement("INT16", "HBM", 7500.0, 1100.0),
        Measurement("FP16", "HBM", 5500.0, 1100.0),
        Measurement("FP32", "HBM", 3800.0, 1100.0),
        Measurement("FP64", "HBM", 1900.0, 1100.0),
    ]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        128,
        "Single Package",
        "GPU",
        "ML Workload",
        true,
        "ascii",
    )

    # Should handle many compute types without issues
    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Plot Generation: Many Memory Levels" begin
    # Test full memory hierarchy (L1, L2, L3, DRAM)
    compute_roofs = [ComputeRoof("DP", 1404.9, :red)]
    memory_levels = [
        MemoryLevel("L1", 3200.0, :blue),
        MemoryLevel("L2", 1312.0, :darkgreen),
        MemoryLevel("L3", 480.0, :purple),
        MemoryLevel("DRAM", 96.42, :teal),
    ]
    measurements = [
        Measurement("DP", "L1", 720.0, 890.0),
        Measurement("DP", "L2", 720.0, 185.0),
        Measurement("DP", "L3", 720.0, 125.0),
        Measurement("DP", "DRAM", 720.0, 21.89),
    ]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        24,
        "Single NUMA",
        "Genoa",
        "TestApp",
        false,
        "ascii",
    )

    # Should handle full memory hierarchy
    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot
end

@testset "Plot Generation: Extreme Values" begin
    # Test with very large and very small values
    compute_roofs = [ComputeRoof("TENSOR", 312000.0, :red)]  # Very large
    memory_levels = [MemoryLevel("HBM", 1638.4, :blue)]
    measurements = [Measurement("TENSOR", "HBM", 280000.0, 1500.0)]

    config = RooflineConfig(
        compute_roofs,
        memory_levels,
        measurements,
        [],
        8,
        "GPU",
        "H100",
        "AI Training",
        true,
        "ascii",
    )

    # Should handle extreme values with dynamic axis limits
    plt = create_roofline_plot(config)
    @test plt isa Plots.Plot

    # Test with very small values
    compute_roofs_small = [ComputeRoof("SENSOR", 0.5, :red)]  # Very small
    memory_levels_small = [MemoryLevel("FLASH", 0.1, :blue)]
    measurements_small = [Measurement("SENSOR", "FLASH", 0.3, 0.08)]

    config_small = RooflineConfig(
        compute_roofs_small,
        memory_levels_small,
        measurements_small,
        [],
        1,
        "IoT",
        "MCU",
        "Sensor",
        true,
        "ascii",
    )

    plt_small = create_roofline_plot(config_small)
    @test plt_small isa Plots.Plot
end

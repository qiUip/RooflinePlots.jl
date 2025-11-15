# Unit tests for types.jl
# Tests basic data structure construction and field access

@testset "ComputeRoof Construction" begin
    roof = ComputeRoof("DP", 150.5, :orange)
    @test roof.name == "DP"
    @test roof.peak_flops == 150.5
    @test roof.color == :orange
end

@testset "MemoryLevel Construction" begin
    mem = MemoryLevel("DRAM", 68.3, :blue)
    @test mem.name == "DRAM"
    @test mem.peak_bw == 68.3
    @test mem.color == :blue
end

@testset "Measurement Construction" begin
    meas = Measurement("DP", "DRAM", 45.2, 60.1)
    @test meas.compute_name == "DP"
    @test meas.memory_name == "DRAM"
    @test meas.flops == 45.2
    @test meas.bandwidth == 60.1
end

@testset "RooflineParams Construction" begin
    # Test with basic memory and compute specs
    memory_specs = Dict("DRAM" => (peak = 100.0, measured = 80.0))
    compute_specs = Dict("DP" => (peak = 200.0, measured = 150.0))

    params = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,  # combined_flops
        [],       # combined_flops_groups
        8,        # num_cores
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    @test params.memory_specs["DRAM"].peak == 100.0
    @test params.memory_specs["DRAM"].measured == 80.0
    @test params.compute_specs["DP"].peak == 200.0
    @test params.compute_specs["DP"].measured == 150.0
    @test params.num_cores == 8
    @test params.topology == "NUMA"
    @test params.cpu_name == "Intel Xeon"
    @test params.app_name == "TestApp"

    # Test with multiple memory and compute types
    memory_specs_multi = Dict(
        "DRAM" => (peak = 100.0, measured = 80.0),
        "L3" => (peak = 300.0, measured = 250.0),
    )
    compute_specs_multi = Dict(
        "DP" => (peak = 200.0, measured = 150.0),
        "SP" => (peak = 400.0, measured = 300.0),
    )

    params_multi = RooflineParams(
        memory_specs_multi,
        compute_specs_multi,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    @test length(params_multi.memory_specs) == 2
    @test length(params_multi.compute_specs) == 2
    @test haskey(params_multi.memory_specs, "DRAM")
    @test haskey(params_multi.memory_specs, "L3")

    # Test with combined measurement
    params_combined = RooflineParams(
        memory_specs,
        Dict(
            "DP" => (peak = 200.0, measured = nothing),
            "SP" => (peak = 400.0, measured = nothing),
        ),
        720.0,  # combined_flops
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )

    @test params_combined.combined_flops == 720.0
    @test isnothing(params_combined.compute_specs["DP"].measured)

    # Test with force_simple flag
    params_simple = RooflineParams(
        memory_specs,
        compute_specs,
        nothing,
        [],
        8,
        "NUMA",
        "Intel Xeon",
        "TestApp",
    )
end

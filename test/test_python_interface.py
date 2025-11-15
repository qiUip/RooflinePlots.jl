#!/usr/bin/env python3
"""
Python Interface Tests for RooflinePlots.jl

This test suite validates the Python utilities for RooflinePlots.jl.
It tests that the python_utils.RooflinePlotter class works correctly
and can create plots without errors.

Run this file to test the Python interface:
    python test/test_python_interface.py

Requirements:
    pip install juliacall

Note: For visual examples, see extensions/python/examples/
"""

import sys
from pathlib import Path

# Add extensions directory to path
REPO_ROOT = Path(__file__).parent.parent.absolute()
sys.path.insert(0, str(REPO_ROOT))

# Import the Python utilities
from extensions.python.python_utils import RooflinePlotter


def test_simple_configuration():
    """Test simple DRAM+DP configuration"""
    print("Testing simple configuration...")

    plotter = RooflinePlotter(repo_root=REPO_ROOT)

    result = plotter.create_plot(
        memory={"DRAM": (204.8, 180.5)},
        compute={"DP": (2150.4, 1245.2)},
        num_cores=64,
        cpu_name="AMD EPYC 7713",
        app_name="Test Simple",
        topology="Dual Socket"
    )

    # Test method chaining returns self
    assert result is plotter, "create_plot() should return self for method chaining"

    # Test that config and plot were created
    assert plotter._config is not None, "Configuration should be created"
    assert plotter._plot is not None, "Plot should be created"

    # Test bottleneck analysis works
    bottleneck = plotter.get_bottleneck()
    assert isinstance(bottleneck, str), "get_bottleneck() should return string"
    assert len(bottleneck) > 0, "Bottleneck analysis should not be empty"

    print("  ✓ Simple configuration works")
    print(f"  ✓ Bottleneck: {bottleneck}")


def test_hierarchical_configuration():
    """Test hierarchical memory configuration"""
    print("Testing hierarchical configuration...")

    plotter = RooflinePlotter(repo_root=REPO_ROOT)

    plotter.create_plot(
        memory={
            "DRAM": (96.42, 21.89),
            "L3": (480.0, 125.0),
            "L2": (1312.0, 185.0),
            "L1": (3200.0, 890.0)
        },
        compute={
            "DP": (1404.9, 720.0),
            "SP": (2809.0, 1440.0)
        },
        num_cores=24,
        cpu_name="AMD Genoa @1.9GHz",
        app_name="Test Hierarchical",
        topology="Single NUMA"
    )

    # Verify hierarchical mode detected
    assert plotter._config is not None, "Configuration should be created"
    assert not plotter._config.simple_mode, "Should use hierarchical mode with 4 memory levels"

    # Verify correct number of memory levels
    mem_count = len(plotter._config.memory_levels)
    assert mem_count == 4, f"Should have 4 memory levels, got {mem_count}"

    # Verify correct number of compute types
    compute_count = len(plotter._config.compute_roofs)
    assert compute_count == 2, f"Should have 2 compute types, got {compute_count}"

    print("  ✓ Hierarchical configuration works")
    print(f"  ✓ Detected {mem_count} memory levels and {compute_count} compute types")


def test_combined_measurements():
    """Test combined DP+SP measurements"""
    print("Testing combined measurements...")

    plotter = RooflinePlotter(repo_root=REPO_ROOT)

    plotter.create_plot(
        memory={
            "DRAM": (96.42, 21.89),
            "L2": (1312.0, 185.0)
        },
        compute={
            "DP": (1404.9, None),   # No individual measurement
            "SP": (2809.0, None)
        },
        combined_flops=720.0,  # Combined measurement
        num_cores=24,
        cpu_name="AMD Genoa @1.9GHz",
        app_name="Test Combined",
        topology="Single NUMA"
    )

    assert plotter._config is not None, "Configuration should be created"

    # Verify combined measurements applied
    # Measurements are stored in config.measurements, not in compute_roofs
    measurements = plotter._config.measurements
    assert len(measurements) > 0, "Should have measurements"

    # Check that measurements exist for both compute types
    compute_names = {m.compute_name for m in measurements}
    assert "DP" in compute_names or "SP" in compute_names, "Should have measurements for DP or SP"

    # All measurements should have the combined_flops value
    for m in measurements:
        assert m.flops == 720.0, f"Measurement for {m.compute_name} should have combined_flops value 720.0"

    print("  ✓ Combined measurements work")
    print(f"  ✓ Generated {len(measurements)} measurement(s) with combined value")


def test_custom_hardware():
    """Test custom hardware types (GPU/HBM)"""
    print("Testing custom hardware types...")

    plotter = RooflinePlotter(repo_root=REPO_ROOT)

    plotter.create_plot(
        memory={
            "HBM": (1200.0, 950.0),
            "L2": (3200.0, 2800.0)
        },
        compute={
            "TENSOR": (5000.0, 4200.0),
            "FP32": (2500.0, 2100.0)
        },
        num_cores=128,
        cpu_name="NVIDIA H100",
        app_name="Test GPU",
        topology="Single GPU"
    )

    assert plotter._config is not None, "Configuration should be created"

    # Verify custom memory types
    mem_names = [mem.name for mem in plotter._config.memory_levels]
    assert "HBM" in mem_names, "Should have HBM memory type"

    # Verify custom compute types
    compute_names = [roof.name for roof in plotter._config.compute_roofs]
    assert "TENSOR" in compute_names, "Should have TENSOR compute type"
    assert "FP32" in compute_names, "Should have FP32 compute type"

    print("  ✓ Custom hardware types work")
    print(f"  ✓ Memory types: {', '.join(mem_names)}")
    print(f"  ✓ Compute types: {', '.join(compute_names)}")


def test_method_chaining():
    """Test that method chaining works properly"""
    print("Testing method chaining...")

    plotter = RooflinePlotter(repo_root=REPO_ROOT)

    # This should work without errors due to method chaining
    result = (plotter
        .create_plot(
            memory={"DRAM": (204.8, 180.5)},
            compute={"DP": (2150.4, 1245.2)},
            num_cores=64,
            cpu_name="AMD EPYC 7713",
            app_name="Test Chaining"
        ))

    assert result is plotter, "Method chain should return plotter instance"

    print("  ✓ Method chaining works")


def test_output_formats():
    """Test different output format options"""
    print("Testing output format options...")

    plotter = RooflinePlotter(repo_root=REPO_ROOT)

    # Test different table formats
    for table_format in ["markdown", "ascii", "org", "csv"]:
        plotter.create_plot(
            memory={"DRAM": (204.8, 180.5)},
            compute={"DP": (2150.4, 1245.2)},
            num_cores=64,
            cpu_name="AMD EPYC 7713",
            app_name=f"Test {table_format}",
            table_format=table_format
        )
        assert plotter._config is not None, f"Config should be created for {table_format} format"

    # Test different plot formats
    for plot_format in ["png", "pdf", "svg"]:
        plotter.create_plot(
            memory={"DRAM": (204.8, 180.5)},
            compute={"DP": (2150.4, 1245.2)},
            num_cores=64,
            cpu_name="AMD EPYC 7713",
            app_name=f"Test {plot_format}",
            plot_format=plot_format
        )
        assert plotter._config is not None, f"Config should be created for {plot_format} format"

    print("  ✓ All output formats work")
    print("  ✓ Table formats: markdown, ascii, org, csv")
    print("  ✓ Plot formats: png, pdf, svg")


def main():
    """Run all Python interface tests"""
    print("="*70)
    print("Python Interface Tests for RooflinePlots.jl")
    print("="*70)
    print()

    tests = [
        ("Simple Configuration", test_simple_configuration),
        ("Hierarchical Configuration", test_hierarchical_configuration),
        ("Combined Measurements", test_combined_measurements),
        ("Custom Hardware Types", test_custom_hardware),
        ("Method Chaining", test_method_chaining),
        ("Output Formats", test_output_formats),
    ]

    passed = 0
    failed = 0

    for test_name, test_func in tests:
        try:
            print(f"Test: {test_name}")
            print("-" * 70)
            test_func()
            print()
            passed += 1
        except AssertionError as e:
            print(f"  ❌ FAILED: {e}")
            print()
            failed += 1
        except Exception as e:
            print(f"  ❌ ERROR: {e}")
            import traceback
            traceback.print_exc()
            print()
            failed += 1

    print("="*70)
    print(f"Test Results: {passed} passed, {failed} failed")
    print("="*70)

    if failed > 0:
        print("\n❌ Some tests failed!")
        sys.exit(1)
    else:
        print("\n✓ All tests passed!")


if __name__ == "__main__":
    main()

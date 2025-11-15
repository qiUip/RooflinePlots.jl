#!/usr/bin/env python3
"""
Combined Measurement Example

This example demonstrates handling scenarios where hardware counters measure
multiple compute types together (e.g., DP+SP combined).

This is common when:
- Hardware counters aggregate multiple operation types
- You want to show combined performance for mixed-precision workloads
- Individual measurements aren't available
"""

import sys
from pathlib import Path

# Add parent directory to path to import python_utils
repo_root = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(repo_root))

from extensions.python.python_utils import RooflinePlotter


def main():
    print("="*70)
    print("Combined Measurement Roofline Example")
    print("="*70)
    print()

    # Create plotter and initialize Julia
    print("Initializing Julia environment...")
    plotter = RooflinePlotter(repo_root=repo_root)

    # Create Roofline plot with combined DP+SP measurement
    print("Creating Roofline plot with combined measurements...")
    plotter.create_plot(
        memory={
            "DRAM": (96.42, 21.89),     # Peak: 96.42 GB/s, Measured: 21.89 GB/s
            "L2": (1312.0, 185.0)        # Peak: 1312.0 GB/s, Measured: 185.0 GB/s
        },
        compute={
            "DP": (1404.9, None),        # Peak: 1404.9 GFLOP/s, no individual measurement
            "SP": (2809.0, None)         # Peak: 2809.0 GFLOP/s, no individual measurement
        },
        combined_flops=720.0,            # Combined DP+SP measured: 720.0 GFLOP/s
        num_cores=24,
        cpu_name="AMD Genoa @1.9GHz",
        app_name="Combined Measurement Example",
        topology="Single NUMA",
        table_format="markdown"
    )

    # Save the plot
    output_file = "combined_roofline.png"
    plotter.save(output_file)
    print(f"✓ Plot saved to: {output_file}")

    # Print performance analysis
    print()
    print("="*70)
    print("PERFORMANCE ANALYSIS")
    print("="*70)
    plotter.print_table()

    # Get bottleneck analysis
    print()
    print(plotter.get_bottleneck())
    print("="*70)
    print()
    print("Note: The combined_flops parameter applies the same measured value")
    print("to both DP and SP, reflecting that hardware counters measured them together.")


if __name__ == "__main__":
    main()

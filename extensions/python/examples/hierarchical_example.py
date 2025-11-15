#!/usr/bin/env python3
"""
Hierarchical Roofline Example

This example demonstrates creating a hierarchical Roofline plot with:
- Full memory hierarchy (L1, L2, L3, DRAM)
- Multiple compute types (Double Precision and Single Precision)

Shows how the application performs across different cache levels.
"""

import sys
from pathlib import Path

# Add parent directory to path to import python_utils
repo_root = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(repo_root))

from extensions.python.python_utils import RooflinePlotter


def main():
    print("="*70)
    print("Hierarchical Roofline Plot Example")
    print("="*70)
    print()

    # Create plotter and initialize Julia
    print("Initializing Julia environment...")
    plotter = RooflinePlotter(repo_root=repo_root)

    # Create a hierarchical Roofline plot with full memory hierarchy
    print("Creating hierarchical Roofline plot...")
    plotter.create_plot(
        memory={
            "DRAM": (96.42, 21.89),    # Peak: 96.42 GB/s, Measured: 21.89 GB/s
            "L3": (480.0, 125.0),       # Peak: 480.0 GB/s, Measured: 125.0 GB/s
            "L2": (1312.0, 185.0),      # Peak: 1312.0 GB/s, Measured: 185.0 GB/s
            "L1": (3200.0, 890.0)       # Peak: 3200.0 GB/s, Measured: 890.0 GB/s
        },
        compute={
            "DP": (1404.9, 720.0),      # Peak: 1404.9 GFLOP/s, Measured: 720.0 GFLOP/s
            "SP": (2809.0, 1440.0)      # Peak: 2809.0 GFLOP/s, Measured: 1440.0 GFLOP/s
        },
        num_cores=24,
        cpu_name="AMD Genoa @1.9GHz",
        app_name="Hierarchical Python Example",
        topology="Single NUMA",
        table_format="markdown"
    )

    # Save the plot
    output_file = "hierarchical_roofline.png"
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
    print("Note: The hierarchical plot shows performance across all cache levels,")
    print("helping identify which memory level is the actual bottleneck.")


if __name__ == "__main__":
    main()

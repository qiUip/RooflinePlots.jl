#!/usr/bin/env python3
"""
Simple Roofline Example

This example demonstrates creating a basic single-level Roofline plot with:
- Single memory level (DRAM)
- Single compute type (Double Precision)

Perfect for getting started with the Python interface.
"""

import sys
from pathlib import Path

# Add parent directory to path to import python_utils
repo_root = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(repo_root))

from extensions.python.python_utils import RooflinePlotter


def main():
    print("="*70)
    print("Simple Roofline Plot Example")
    print("="*70)
    print()

    # Create plotter and initialize Julia
    print("Initializing Julia environment...")
    plotter = RooflinePlotter(repo_root=repo_root)

    # Create a simple Roofline plot
    print("Creating Roofline plot...")
    plotter.create_plot(
        memory={
            "DRAM": (204.8, 180.5)  # Peak: 204.8 GB/s, Measured: 180.5 GB/s
        },
        compute={
            "DP": (2150.4, 1245.2)   # Peak: 2150.4 GFLOP/s, Measured: 1245.2 GFLOP/s
        },
        num_cores=64,
        cpu_name="AMD EPYC 7713",
        app_name="Simple Python Example",
        topology="Dual Socket"
    )

    # Save the plot
    output_file = "simple_roofline.png"
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


if __name__ == "__main__":
    main()

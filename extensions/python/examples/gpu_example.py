#!/usr/bin/env python3
"""
GPU/Accelerator Roofline Example

This example demonstrates creating Roofline plots for GPUs and accelerators with:
- Custom memory types (HBM instead of DRAM)
- Custom compute types (Tensor cores, FP32)
- Different performance characteristics than CPUs

Shows the flexibility of RooflinePlots.jl for various hardware architectures.
"""

import sys
from pathlib import Path

# Add parent directory to path to import python_utils
repo_root = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(repo_root))

from extensions.python.python_utils import RooflinePlotter


def main():
    print("="*70)
    print("GPU/Accelerator Roofline Plot Example")
    print("="*70)
    print()

    # Create plotter and initialize Julia
    print("Initializing Julia environment...")
    plotter = RooflinePlotter(repo_root=repo_root)

    # Create Roofline plot for GPU with custom hardware types
    print("Creating GPU Roofline plot...")
    plotter.create_plot(
        memory={
            "HBM": (1200.0, 950.0),      # Peak: 1200.0 GB/s, Measured: 950.0 GB/s
            "L2": (3200.0, 2800.0)       # Peak: 3200.0 GB/s, Measured: 2800.0 GB/s
        },
        compute={
            "TENSOR": (5000.0, 4200.0),  # Peak: 5000.0 GFLOP/s, Measured: 4200.0 GFLOP/s
            "FP32": (2500.0, 2100.0)     # Peak: 2500.0 GFLOP/s, Measured: 2100.0 GFLOP/s
        },
        num_cores=128,                    # Number of SMs/CUs
        cpu_name="NVIDIA H100",
        app_name="GPU Deep Learning Example",
        topology="Single GPU",
        table_format="markdown"
    )

    # Save the plot
    output_file = "gpu_roofline.png"
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
    print("Note: RooflinePlots.jl supports arbitrary memory and compute types,")
    print("making it suitable for GPUs, FPGAs, ASICs, and other accelerators.")


if __name__ == "__main__":
    main()

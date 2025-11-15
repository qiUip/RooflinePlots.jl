# Python Interface Guide

This guide explains how to use RooflinePlots.jl from Python via [JuliaCall](https://github.com/JuliaPy/PythonCall.jl).

## Overview

The Python interface provides a clean, Pythonic API for creating Roofline plots
without the raw Julia interop.

## Quick Start

```python
from extensions.python.python_utils import RooflinePlotter

plotter = RooflinePlotter()

plotter.create_plot(
    memory={"DRAM": (204.8, 180.5)},      # (peak GB/s, measured GB/s)
    compute={"DP": (2150.4, 1245.2)},     # (peak GFLOP/s, measured GFLOP/s)
    num_cores=64,
    cpu_name="AMD EPYC 7713",
    app_name="My Application"
).save("roofline.png").print_table()
```

## Installation

```bash
pip install juliacall
```

JuliaCall will automatically download and manage Julia if needed.

## Python Utilities

### `python_utils.py`

Provides the `RooflinePlotter` class - a Pythonic wrapper around RooflinePlots.jl:

**Main Methods:**

- `create_plot(...)` - Create a Roofline plot with Python dictionaries
- `save(filename)` - Save plot to file
- `print_table()` - Print performance analysis table
- `get_bottleneck()` - Get bottleneck analysis string

**Convenience Function:**

- `create_simple_plot(...)` - Quick function for simple single-level plots

## Examples

The `examples/` directory contains standalone Python scripts demonstrating
different use cases:

1. **`simple_example.py`**
   - Basic single-level Roofline (DRAM + DP)
   - Perfect for getting started
2. **`hierarchical_example.py`**
   - Full memory hierarchy (L1, L2, L3, DRAM)
   - Multiple compute types (DP, SP)
   - Demonstrates hierarchical mode
3. **`combined_measurement_example.py`**
   - Combined DP+SP measurements
   - For when hardware counters measure multiple types together
4. **`gpu_example.py`**
   - GPU/accelerator configuration
   - Custom hardware types (HBM, Tensor cores)

### Running Examples

```bash
# From repository root
python extensions/python/examples/simple_example.py
python extensions/python/examples/hierarchical_example.py
python extensions/python/examples/combined_measurement_example.py
python extensions/python/examples/gpu_example.py
```

Each example is self-contained and generates a Roofline plot with performance analysis.

## Testing

Python interface tests are located in `test/test_python_interface.py`. These
tests validate the utility functions work correctly:

```bash
python test/test_python_interface.py
```

## Raw Julia Interop (Advanced)

For advanced users who want to extend the functionality, it is possible
to sidestep the provided `python_utils.py` and directly call Julia functions.

```python
from juliacall import Main as jl

jl.seval("using RooflinePlots")
memory_specs = jl.seval('Dict("DRAM" => (peak=204.8, measured=180.5))')
compute_specs = jl.seval('Dict("DP" => (peak=2150.4, measured=1245.2))')
params = jl.RooflineParams(memory_specs, compute_specs, None, [], 64, "Dual Socket", "AMD EPYC 7713", "My App")
config = jl.params_to_config(params)
plt = jl.create_roofline_plot(config)
jl.savefig(plt, "roofline.png")
```

## Common Troubleshooting

**Module not found error:**

```bash
# Add to PYTHONPATH from repository root:
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

**Julia version issues:**

```bash
# JuliaCall manages Julia automatically
# To reset the environment:
rm -rf ~/.julia/juliaup
```

**Display issues:**

```python
# Ensure Plots backend is set
from juliacall import Main as jl
jl.seval("using Plots; gr()")
```

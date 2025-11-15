# Python Interface for RooflinePlots.jl

This directory contains Python utilities and examples for using RooflinePlots.jl from Python via [JuliaCall](https://github.com/JuliaPy/PythonCall.jl).

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

## Contents

- **`python_utils.py`** - Pythonic wrapper providing the `RooflinePlotter` class
- **`examples/`** - Standalone example scripts:
  - `simple_example.py` - Basic DRAM+DP example
  - `hierarchical_example.py` - Full memory hierarchy
  - `combined_measurement_example.py` - Combined measurements
  - `gpu_example.py` - Custom hardware types (GPU/HBM)

## Documentation

See the [Python Interface Guide](../../docs/src/python.md) for complete documentation, API reference, and detailed examples.

## Running Examples

```bash
# From repository root
python extensions/python/examples/simple_example.py
python extensions/python/examples/hierarchical_example.py
python extensions/python/examples/combined_measurement_example.py
python extensions/python/examples/gpu_example.py
```

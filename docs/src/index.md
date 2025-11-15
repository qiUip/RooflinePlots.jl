# RooflinePlots.jl

A Julia package for generating Roofline Model visualizations and performance analysis.

## About this package

The Roofline Model visualizes performance limits based on computational
throughput (FLOP/s) and memory bandwidth (GB/s), helping identify whether
applications are compute-bound or memory-bound.

RooflinePlots.jl generates roofline plots and performance analysis for CPU,
GPU, and accelerator workloads. It provides both command-line and programmatic
interfaces for creating visualizations from hardware performance measurements.

The motivation for this project came from trying to collect and compare
performance metrics from various tools such as
[likwid](https://github.com/RRZE-HPC/likwid) and
[PAPI](https://github.com/icl-utk-edu/papi), and present them in a uniform
manner in reports, documentation and publications.

## Key Features

### Generic Type System

Define arbitrary memory and compute types that match your hardware:

- **Memory types**: DRAM, HBM, DDR5, L1, L2, L3, or custom names
- **Compute types**: DP, SP, FP16, TENSOR, AVX512, INT8, or custom names

The package automatically orders and labels performance lines based on specifications.

### Hierarchical Memory Analysis

Visualize full memory hierarchies (L1/L2/L3/DRAM) with automatic log-log scaling
when multiple memory levels are specified. Simple mode with linear scaling is
used for single-level analysis.

### Combined Measurements

Handle hardware counters that measure multiple compute types together (e.g.,
DP+SP, FP32+TENSOR), reflecting real measurement constraints.

### Performance Analysis

- Automatic bottleneck detection (memory-bound vs compute-bound)
- Performance tables showing efficiency percentages
- Arithmetic intensity calculations
- Multiple output formats (ASCII, Markdown, Org-mode, CSV)

### Flexible Interfaces

- Command-line interface for quick analysis
- Julia API for programmatic use
- Python interface via JuliaCall

### Customization

- Custom color palettes for memory and compute lines
- Ridge point visualization control
- Force linear or log-log scaling
- Configurable output formats

## Quick Example

```bash
./roofline.jl \
    --peak-bw-DRAM=204.8 \
    --measured-bw-DRAM=180.5 \
    --peak-flops-DP=2150.4 \
    --measured-flops-DP=1245.2 \
    --cpu-name="AMD EPYC 7713" \
    --app-name="My Application"
```

This generates a roofline plot showing performance limits, measured performance
points, and bottleneck analysis.

## Installation

### From GitHub

```julia
using Pkg
Pkg.add(url="https://github.com/qiUip/RooflinePlots.jl.git")
```

### Development

```bash
git clone https://github.com/qiUip/RooflinePlots.jl.git
cd RooflinePlots.jl
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Documentation

- **[User Guide](usage.md)** - Command-line and Julia API usage with examples
- **[Python Integration](python.md)** - Using RooflinePlots.jl from Python
- **[Examples](examples.md)** - Gallery of plots for different configurations
- **[API Reference](api.md)** - Complete function and type documentation
- **[Testing Guide](testing.md)** - Running and writing tests

## Project Status

This package is under active development. The API is subject to change before
the 1.0 release.

**Compatibility**: Julia 1.6+

## License

This project is licensed under the MIT License - see the LICENSE file for details.

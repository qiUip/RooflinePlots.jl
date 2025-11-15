# RooflinePlots.jl

[![CI](https://github.com/qiUip/RooflinePlots.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/qiUip/RooflinePlots.jl/actions/workflows/CI.yml)
[![Documentation](https://github.com/qiUip/RooflinePlots.jl/actions/workflows/Documentation.yml/badge.svg)](https://github.com/qiUip/RooflinePlots.jl/actions/workflows/Documentation.yml)

A Julia package for generating Roofline Model visualizations and performance analysis.

## Overview

The Roofline Model helps identify whether applications are compute-bound or memory-bound by visualizing performance limits based on computational throughput (FLOP/s) and memory bandwidth (GB/s).

**Key Features:**
- **Generic type system** - Use any memory types (DRAM, HBM, L1-L3) and compute types (DP, SP, TENSOR, etc.)
- **Hierarchical mode** - Visualize full memory hierarchy with log-log scaling
- **Combined measurements** - Handle hardware counters that measure multiple types together
- **Performance analysis** - Automatic bottleneck detection and performance tables
- **Flexible I/O** - Command-line interface and Julia API

## Quick Start

### Command Line

```bash
./roofline.jl \
    --peak-bw-DRAM=204.8 \
    --measured-bw-DRAM=180.5 \
    --peak-flops-DP=2150.4 \
    --measured-flops-DP=1245.2 \
    --cpu-name="AMD EPYC 7713" \
    --app-name="My Application"
```

### Julia API

```julia
using RooflinePlots

memory_specs = Dict("DRAM" => (peak=204.8, measured=180.5))
compute_specs = Dict("DP" => (peak=2150.4, measured=1245.2))

params = RooflineParams(
    memory_specs, compute_specs, nothing, [],
    64, "Dual Socket", "AMD EPYC 7713", "My Application"
)

config = params_to_config(params)
plt = create_roofline_plot(config)
savefig(plt, "roofline.png")
print_performance_table(config)
```

### Python API

RooflinePlots.jl can be called from Python using [JuliaCall](https://github.com/JuliaPy/PythonCall.jl):

```bash
pip install juliacall
```

RooflinePlots.jl offers a Python utility to simplify the interface. See the [Python Interface Guide](https://qiUip.github.io/RooflinePlots.jl/dev/python/) for detailed documentation and examples.

## Examples

The package can generate plots for various configurations:

- **Simple mode**: Single memory level with linear scales
- **Hierarchical mode**: Multiple memory levels (L1/L2/L3/DRAM) with log-log scales
- **Combined measurements**: Handle hardware counters measuring multiple types together
- **Custom types**: Support for any memory (HBM, DDR5) and compute types (TENSOR, INT8, etc.)

**See the [Examples Gallery](https://qiUip.github.io/RooflinePlots.jl/dev/examples/)** for visual examples of all configurations.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/qiUip/RooflinePlots.jl.git")
```

## Documentation

**Full documentation:** [https://qiUip.github.io/RooflinePlots.jl/dev](https://qiUip.github.io/RooflinePlots.jl/dev)

- **[User Guide](https://qiUip.github.io/RooflinePlots.jl/dev/usage/)** - Detailed examples and all command-line options
- **[Python Integration](https://qiUip.github.io/RooflinePlots.jl/dev/python/)** - Using RooflinePlots.jl from Python
- **[Examples](https://qiUip.github.io/RooflinePlots.jl/dev/examples/)** - Gallery of plots for different configurations
- **[API Reference](https://qiUip.github.io/RooflinePlots.jl/dev/api/)** - Complete function and type documentation
- **[Testing Guide](https://qiUip.github.io/RooflinePlots.jl/dev/testing/)** - How to run and write tests

## Testing

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

The Roofline Model was developed by Samuel Williams, Andrew Waterman, and David Patterson at UC Berkeley.

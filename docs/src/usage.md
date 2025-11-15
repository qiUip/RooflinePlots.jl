# User Guide

This guide shows how to use RooflinePlots.jl to create roofline plots and
analyze performance.

## Command Line Usage

The simplest way to use RooflinePlots.jl is via the command line interface.  

### Basic Example

```bash
./roofline.jl \
    --peak-bw-DRAM=204.8 \
    --measured-bw-DRAM=180.5 \
    --peak-flops-DP=2150.4 \
    --measured-flops-DP=1245.2 \
    --cpu-name="AMD EPYC 7713" \
    --app-name="My Application"
```

### Multi-Level Memory Hierarchy

```bash
./roofline.jl \
    --peak-bw-DRAM=96.42 \
    --measured-bw-DRAM=21.89 \
    --peak-bw-L3=480.0 \
    --measured-bw-L3=125.0 \
    --peak-bw-L2=1312.0 \
    --measured-bw-L2=185.0 \
    --peak-bw-L1=3200.0 \
    --measured-bw-L1=890.0 \
    --peak-flops-DP=1404.9 \
    --measured-flops-DP=720.0 \
    --num-cores=24 \
    --topology="Single NUMA" \
    --cpu-name="Genoa @1.9GHz" \
    --app-name="Full Hierarchy"
```

### Multiple Compute Types

```bash
./roofline.jl \
    --peak-bw-DRAM=102.4 \
    --measured-bw-DRAM=78.3 \
    --peak-flops-DP=1200.0 \
    --measured-flops-DP=650.0 \
    --peak-flops-SP=2400.0 \
    --measured-flops-SP=1280.0 \
    --peak-flops-DP_AVX=1920.0 \
    --measured-flops-DP_AVX=1050.0 \
    --peak-flops-SP_AVX=3840.0 \
    --measured-flops-SP_AVX=2100.0 \
    --num-cores=16 \
    --topology="Single Socket" \
    --cpu-name="AMD EPYC" \
    --app-name="Matrix Multiply"
```

### Combined Measurements

When hardware counters measure multiple compute types together:

```bash
# Specific types combined
./roofline.jl \
    --peak-bw-HBM=1200.0 \
    --measured-bw-HBM=980.0 \
    --peak-flops-FP32=19500.0 \
    --peak-flops-TENSOR=156000.0 \
    --measured-flops-FP32-TENSOR=145000.0 \
    --num-cores=80 \
    --topology="GPU" \
    --cpu-name="NVIDIA A100" \
    --app-name="Deep Learning"

# All types combined
./roofline.jl \
    --peak-bw-DRAM=102.4 \
    --measured-bw-DRAM=78.3 \
    --peak-flops-DP=1200.0 \
    --peak-flops-SP=2400.0 \
    --measured-flops=1850.0 \
    --num-cores=16 \
    --topology="Dual Socket" \
    --cpu-name="Intel Xeon" \
    --app-name="Mixed Precision"
```

### Custom Colors

```bash
./roofline.jl \
    --peak-bw-DRAM=204.8 \
    --measured-bw-DRAM=180.5 \
    --peak-bw-L3=1200.0 \
    --measured-bw-L3=950.0 \
    --peak-flops-DP=2150.4 \
    --measured-flops-DP=1245.2 \
    --peak-flops-SP=4300.0 \
    --measured-flops-SP=2500.0 \
    --mem-colors="#3498DB,#2ECC71" \
    --compute-colors="orange,purple"
```

### Output Options

```bash
./roofline.jl \
    --peak-bw-DRAM=204.8 \
    --measured-bw-DRAM=180.5 \
    --peak-flops-DP=2150.4 \
    --measured-flops-DP=1245.2 \
    --output=my_plot.png \
    --table-format=markdown \
    --save-table \
    --quiet \
    --hide-ridges \
    --force-simple
```

## Command Line Options

RooflinePlots.jl offers a flexible approach for defining arbitrary memory and
compute types with the following command line options, meta-data to use for the
plot labelling, and several output options to produce rooflines in a customised
style.

### Memory and Compute Specifications

**Memory bandwidth** (at least one required):

- `--peak-bw-<TYPE>=<value>` - Peak bandwidth in GB/s
- `--measured-bw-<TYPE>=<value>` - Measured bandwidth in GB/s

Examples: `--peak-bw-DRAM=204.8`, `--peak-bw-HBM=1200.0`, `--peak-bw-L3=480.0`

**Compute performance** (at least one required):

- `--peak-flops-<TYPE>=<value>` - Peak performance in GFLOP/s
- `--measured-flops-<TYPE>=<value>` - Measured performance in GFLOP/s

Examples: `--peak-flops-DP=2150.4`, `--peak-flops-TENSOR=156000.0`

**Combined measurements**:

- `--measured-flops=<value>` - All compute types combined
- `--measured-flops-<TYPE1>-<TYPE2>=<value>` - Specific types combined

Examples: `--measured-flops=720.0`, `--measured-flops-DP-SP=720.0`

**Requirements**:

- Each memory type needs both peak and measured values
- Each compute peak needs either an individual measurement or inclusion in a
  combined measurement

**Type naming**: Avoid hyphens in type names (use underscores instead: `DP_AVX`,
`FP32_TENSOR`)

### Metadata

- `--num-cores=<N>` - Number of cores (default: omitted from filename)
- `--topology=<string>` - Topology description (default: "Topology")
- `--cpu-name=<string>` - CPU/GPU model name (default: "CPU")
- `--app-name=<string>` - Application name (default: "Application")

### Output Control

- `--output=<file>`, `-o <file>` - Output filename (auto-generated if not specified)
- `--quiet`, `-q` - Suppress table output
- `--show`, `-s` - Display plot window
- `--hide-ridges` - Hide ridge point lines
- `--force-simple` - Force linear scaling
- `--table-format=<fmt>` - Table format: `ascii`, `org`, `markdown`, or `csv`
- `--save-table` - Save table to file with appropriate extension
- `--plot-format=<fmt>` - Plot format: png, pdf, or svg (default: png)

### Colors

- `--mem-colors=<colors>` - Memory colors (comma-separated)
- `--compute-colors=<colors>` - Compute colors (comma-separated)

Supported formats: color names (`red`, `blue`, `orange`) or hex codes
(`#FF5733`, `#3498DB`)

All [Julia named
colors](https://juliagraphics.github.io/Colors.jl/stable/namedcolors/) are
supported

## Julia API

As well as the command line options, RooflinePlots.jl can be used as a library
with simple API for direct integration within other Julia programs.

### Basic Example

```julia
using RooflinePlots

memory_specs = Dict("DRAM" => (peak=204.8, measured=180.5))
compute_specs = Dict("DP" => (peak=2150.4, measured=1245.2))

params = RooflineParams(
    memory_specs,
    compute_specs,
    nothing,  # combined_flops
    [],       # combined_flops_groups
    64,       # num_cores
    "Dual Socket",
    "AMD EPYC 7713",
    "My Application"
)

config = params_to_config(params)
plt = create_roofline_plot(config)
savefig(plt, "roofline.png")
print_performance_table(config)
```

### Hierarchical Memory

```julia
memory_specs = Dict(
    "DRAM" => (peak=96.42, measured=21.89),
    "L3"   => (peak=480.0, measured=125.0),
    "L2"   => (peak=1312.0, measured=185.0),
    "L1"   => (peak=3200.0, measured=890.0)
)

compute_specs = Dict("DP" => (peak=1404.9, measured=720.0))

params = RooflineParams(
    memory_specs, compute_specs, nothing, [],
    24, "Single NUMA", "Genoa @1.9GHz", "TestApp"
)

config = params_to_config(params)
plt = create_roofline_plot(config)
savefig(plt, "hierarchical.png")
```

### Multiple Compute Types

```julia
memory_specs = Dict("DRAM" => (peak=102.4, measured=78.3))

compute_specs = Dict(
    "DP"     => (peak=1200.0, measured=650.0),
    "SP"     => (peak=2400.0, measured=1280.0),
    "DP_AVX" => (peak=1920.0, measured=1050.0),
    "SP_AVX" => (peak=3840.0, measured=2100.0)
)

params = RooflineParams(
    memory_specs, compute_specs, nothing, [],
    16, "Single Socket", "AMD EPYC", "Matrix Multiply"
)
```

### Combined Measurements

```julia
memory_specs = Dict("HBM" => (peak=1200.0, measured=980.0))

# Peak performance without individual measurements
compute_specs = Dict(
    "FP32"   => (peak=19500.0, measured=nothing),
    "TENSOR" => (peak=156000.0, measured=nothing)
)

# Hardware counter measured both together
combined_groups = [
    (["FP32", "TENSOR"], 145000.0)
]

params = RooflineParams(
    memory_specs, compute_specs, nothing, combined_groups,
    80, "GPU", "NVIDIA A100", "Deep Learning"
)
```

### Custom Colors

```julia
memory_specs = Dict(
    "DRAM" => (peak=204.8, measured=180.5),
    "L3"   => (peak=1200.0, measured=950.0)
)

compute_specs = Dict(
    "DP" => (peak=2150.4, measured=1245.2),
    "SP" => (peak=4300.0, measured=2500.0)
)

params = RooflineParams(
    memory_specs, compute_specs, nothing, [],
    64, "Dual Socket", "AMD EPYC 7713", "My Application"
)

output_opts = OutputOptions(
    mem_colors = [:cyan, :magenta],
    compute_colors = [:orange, "#FF5733"]
)

config = params_to_config(params, output_opts)
plt = create_roofline_plot(config)
savefig(plt, "custom_colors.png")
```

## Understanding the Output

### Plot Elements

- **Diagonal lines**: Memory bandwidth limits (slope = bandwidth)
- **Horizontal lines**: Compute performance ceilings
- **Ridge points**: Intersections where bottleneck transitions
- **Markers**: Measured performance points with circle fill color matching the
  memory level and stroke color matching the compute type (for multiple compute
  types)

### Performance Table

Shows for each compute type:

- Measured performance as percentage of peak
- Arithmetic intensity (FLOP/Byte) for each memory level
- Identified bottleneck

### Bottleneck Types

- **Memory-bound (COMPUTE/MEMORY)**: Limited by a specific combination of
  compute throughput and memory bandwidth
   - Example: "Memory-bound (DP/DRAM)"
- **Compute-bound (COMPUTE)**: Limited by any compute throughput
   - Example: "Compute-bound"

**Selection priority**: Memory-bound bottleneck determination uses the highest
measured compute type paired with the slowest memory level

### Plot Modes

**Simple mode** (linear scales):

- Single memory level, or `--force-simple` flag
- Linear x and y axes

**Hierarchical mode** (log-log scales):

- Multiple memory levels
- Log-log scales with ridge points

## Plots Output Formats

Plots can be saved in various formats for easy integration into documents.  

The format can be selected either by the extension of the filename when
`--output` is selected, or with `--plot-format` when the automatic naming
convention is used.

**Format Options**:

- `PNG`
- `PDF`
- `SVG`

### Examples

```bash
# Save plot as PNG (default)
./roofline.jl --peak-flops-DP=200 --measured-flops-DP=150 \
    --peak-bw-DRAM=100 --measured-bw-DRAM=80 \
    --output=roofline.png

# Save plot as PDF with the default output naming convention
./roofline.jl --peak-flops-DP=200 --measured-flops-DP=150 \
    --peak-bw-DRAM=100 --measured-bw-DRAM=80 \
    --plot-format=pdf

# Save plot as SVG using specified output name
./roofline.jl --peak-flops-DP=200 --measured-flops-DP=150 \
    --peak-bw-DRAM=100 --measured-bw-DRAM=80 \
    --output=roofline.svg
```

## Table Output Formats

Several formatting options are available for the analysis tables for easy
integration into documents.

**Format Options**

- `ascii` - Text table (`.dat` file)
- `markdown` - Markdown (`.md` file)
- `org` - Org-mode table (`.org` file)
- `csv` - Comma-separated values (`.csv` file)

### Examples

```bash
# Print markdown table to console
./roofline.jl --peak-flops-DP=200 --measured-flops-DP=150 \
    --peak-bw-DRAM=100 --measured-bw-DRAM=80 \
    --table-format=markdown

# Save CSV table to file
./roofline.jl --peak-flops-DP=200 --measured-flops-DP=150 \
    --peak-bw-DRAM=100 --measured-bw-DRAM=80 \
    --table-format=csv --save-table

# Quiet mode with saved markdown table
./roofline.jl --peak-flops-DP=200 --measured-flops-DP=150 \
    --peak-bw-DRAM=100 --measured-bw-DRAM=80 \
    --table-format=markdown --save-table --quiet
```

## Getting Help

```bash
# Command line help
./roofline.jl --help

# Julia documentation
julia> using RooflinePlots
julia> ?RooflineParams
julia> ?create_roofline_plot
```

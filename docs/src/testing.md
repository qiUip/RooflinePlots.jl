# Testing Guide

## Running Tests

### Complete Test Suite

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

### Unit Tests

Run all unit tests:

```bash
julia --project=. test/run_unit_tests.jl
```

Run specific modules:

```bash
julia --project=. test/run_unit_tests.jl types      # Type constructors
julia --project=. test/run_unit_tests.jl config     # Configuration
julia --project=. test/run_unit_tests.jl analysis   # Bottleneck detection
julia --project=. test/run_unit_tests.jl reporting  # Performance tables
julia --project=. test/run_unit_tests.jl cli        # CLI parsing
julia --project=. test/run_unit_tests.jl plotting   # Plot generation
```

### Integration Tests

```bash
julia --project=. test/run_integration_tests.jl
```

### Python Interface Tests

```bash
python test/test_python_interface.py
```

Requires: `pip install juliacall`

### Cleanup

```bash
julia --project=. test/run_unit_tests.jl clean
julia --project=. test/run_integration_tests.jl clean
```

## Test Organization

```
test/
├── runtests.jl                  # Main test runner (Pkg.test())
├── run_unit_tests.jl            # Unit test runner
├── run_integration_tests.jl     # Integration test runner
├── test_types.jl                # Type constructors
├── test_config.jl               # Configuration conversion
├── test_analysis.jl             # Bottleneck detection
├── test_reporting.jl            # Performance tables
├── test_cli.jl                  # CLI argument parsing
├── test_plotting.jl             # Plot generation
├── test_table_formats.jl        # Table output formats
├── test_integration.jl          # End-to-end workflows
├── test_python_interface.py     # Python interface
└── examples/                    # Generated examples
```

## Test Coverage

**Unit Tests** - Individual functions and modules:

- Type constructors and validation
- Configuration conversion
- Bottleneck detection
- Performance table formatting
- CLI argument parsing
- Plot generation

**Integration Tests** - End-to-end workflows:

- Simple DRAM+DP configuration
- Hierarchical memory (L1/L2/L3/DRAM)
- Multiple compute types
- Combined measurements
- Custom colors
- Table output formats

**Python Tests** - Python interface via JuliaCall:

- RooflinePlotter utility class
- All major use cases
- Plot generation from Python

## Example Outputs

Integration tests generate plots and tables in `test/examples/` (see
**[Examples](examples.md)** for reference):

```bash
ls test/examples/
# *.svg - Roofline plots
# *.md - Table outputs
```

See `test/examples/README.md` for descriptions.

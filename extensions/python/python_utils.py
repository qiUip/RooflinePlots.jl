"""
Python utilities for RooflinePlots.jl

This module provides a cleaner Python interface to RooflinePlots.jl by wrapping
the Julia calls with Pythonic functions.

Usage:
    from test.python_utils import RooflinePlotter

    plotter = RooflinePlotter()

    plotter.create_plot(
        memory={"DRAM": (204.8, 180.5)},
        compute={"DP": (2150.4, 1245.2)},
        num_cores=64,
        cpu_name="AMD EPYC 7713",
        app_name="My Application"
    )

    plotter.save("roofline.png")
    plotter.print_table()
"""

from typing import Dict, Tuple, Optional, List
from pathlib import Path


class RooflinePlotter:
    """
    A Pythonic wrapper around RooflinePlots.jl

    This class provides a cleaner interface for creating Roofline plots from Python,
    hiding the Julia interop complexity.
    """

    def __init__(self, repo_root: Optional[Path] = None):
        """
        Initialize the plotter and load Julia packages.

        Args:
            repo_root: Path to RooflinePlots.jl repository. If None, auto-detects.
        """
        from juliacall import Main as jl

        self.jl = jl
        self._config = None
        self._plot = None

        # Add local package if repo_root provided
        if repo_root:
            # Develop the package and explicitly add Plots
            self.jl.seval(f'''
                using Pkg
                Pkg.develop(path="{repo_root}")
                Pkg.add("Plots")
            ''')

        # Load packages
        self.jl.seval("using RooflinePlots")
        self.jl.seval("using Plots")

    def create_plot(
        self,
        memory: Dict[str, Tuple[float, float]],
        compute: Dict[str, Tuple[float, float]],
        num_cores: int,
        cpu_name: str,
        app_name: str,
        topology: str = "Dual Socket",
        combined_flops: Optional[float] = None,
        combined_groups: Optional[List[Tuple[List[str], float]]] = None,
        force_simple: bool = False,
        table_format: str = "markdown",
        plot_format: str = "png"
    ):
        """
        Create a Roofline plot with the given specifications.

        Args:
            memory: Dict mapping memory types to (peak_bw, measured_bw) tuples in GB/s
            compute: Dict mapping compute types to (peak_flops, measured_flops) tuples in GFLOP/s
            num_cores: Number of cores
            cpu_name: Name of the CPU/processor
            app_name: Name of the application
            topology: System topology description
            combined_flops: Single measured value for all compute types (optional)
            combined_groups: List of (types, measured) for specific combined groups (optional)
            force_simple: Force simple mode instead of hierarchical
            table_format: Table format: "ascii", "markdown", "org", or "csv"
            plot_format: Plot format: "png", "pdf", or "svg"

        Example:
            plotter.create_plot(
                memory={"DRAM": (204.8, 180.5)},
                compute={"DP": (2150.4, 1245.2)},
                num_cores=64,
                cpu_name="AMD EPYC 7713",
                app_name="My App"
            )
        """
        # Convert Python dicts to Julia format
        memory_specs = self._make_julia_dict(memory, named_tuple=True)
        compute_specs = self._make_julia_dict(compute, named_tuple=True)

        # Handle combined groups if provided
        if combined_groups is None:
            combined_groups_jl = "[]"
        else:
            group_parts = []
            for types, measured in combined_groups:
                types_str = '", "'.join(types)
                group_parts.append(f'(["{types_str}"], {measured})')
            groups_str = ", ".join(group_parts)
            combined_groups_jl = f"[{groups_str}]"

        # Create parameters
        combined_flops_str = str(combined_flops) if combined_flops is not None else "nothing"

        params_code = f"""
        RooflineParams(
            {memory_specs},
            {compute_specs},
            {combined_flops_str},
            {combined_groups_jl},
            {num_cores},
            "{topology}",
            "{cpu_name}",
            "{app_name}"
        )
        """

        params = self.jl.seval(params_code)

        # Create output options
        output_opts = self.jl.OutputOptions(
            force_simple=force_simple,
            table_format=table_format,
            plot_format=plot_format
        )

        # Generate configuration and plot
        self._config = self.jl.params_to_config(params, output_opts)
        self._plot = self.jl.create_roofline_plot(self._config)

        return self

    def save(self, filename: str):
        """
        Save the plot to a file.

        Args:
            filename: Output filename (e.g., "roofline.png")
        """
        if self._plot is None:
            raise RuntimeError("No plot created. Call create_plot() first.")

        self.jl.savefig(self._plot, filename)
        return self

    def print_table(self):
        """Print the performance analysis table."""
        if self._config is None:
            raise RuntimeError("No configuration created. Call create_plot() first.")

        self.jl.print_performance_table(self._config)
        return self

    def get_bottleneck(self) -> str:
        """
        Get the bottleneck analysis string.

        Returns:
            String describing whether the application is memory-bound or compute-bound
        """
        if self._config is None:
            raise RuntimeError("No configuration created. Call create_plot() first.")

        return str(self.jl.determine_bottleneck(self._config))

    def _make_julia_dict(self, python_dict: Dict, named_tuple: bool = False) -> str:
        """
        Convert a Python dictionary to Julia Dict syntax.

        Args:
            python_dict: Python dict to convert
            named_tuple: If True, values are (peak, measured) tuples

        Returns:
            Julia Dict string
        """
        if named_tuple:
            items = []
            for key, (peak, measured) in python_dict.items():
                measured_str = str(measured) if measured is not None else "nothing"
                items.append(f'"{key}" => (peak={peak}, measured={measured_str})')
            return f"Dict({', '.join(items)})"
        else:
            items = [f'"{k}" => {v}' for k, v in python_dict.items()]
            return f"Dict({', '.join(items)})"


def create_simple_plot(
    memory_type: str,
    memory_peak: float,
    memory_measured: float,
    compute_type: str,
    compute_peak: float,
    compute_measured: float,
    num_cores: int,
    cpu_name: str,
    app_name: str,
    output_file: str = "roofline.png",
    show_table: bool = True
) -> RooflinePlotter:
    """
    Convenience function for creating a simple single-level Roofline plot.

    Args:
        memory_type: Memory type name (e.g., "DRAM")
        memory_peak: Peak memory bandwidth in GB/s
        memory_measured: Measured memory bandwidth in GB/s
        compute_type: Compute type name (e.g., "DP")
        compute_peak: Peak compute performance in GFLOP/s
        compute_measured: Measured compute performance in GFLOP/s
        num_cores: Number of cores
        cpu_name: CPU name
        app_name: Application name
        output_file: Output filename
        show_table: Whether to print performance table

    Returns:
        RooflinePlotter instance

    Example:
        create_simple_plot(
            "DRAM", 204.8, 180.5,
            "DP", 2150.4, 1245.2,
            64, "AMD EPYC 7713", "My App"
        )
    """
    plotter = RooflinePlotter()

    plotter.create_plot(
        memory={memory_type: (memory_peak, memory_measured)},
        compute={compute_type: (compute_peak, compute_measured)},
        num_cores=num_cores,
        cpu_name=cpu_name,
        app_name=app_name
    )

    plotter.save(output_file)

    if show_table:
        plotter.print_table()

    return plotter

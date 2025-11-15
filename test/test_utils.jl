"""
Test Utilities

Shared helper functions for test suite.
"""

"""
    cleanup_examples()

Clean up generated example files from the test examples directory.

Removes all PNG, SVG, PDF, ASCII, Markdown and Org-mode files generated during test runs.
Used by both unit and integration test runners.
"""
function cleanup_examples()
    examples_dir = joinpath(@__DIR__, "examples")
    if isdir(examples_dir)
        # files to keep 
        keep = Set(["README.md"])

        # file extensions to clean up
        exts = [".png", ".svg", ".pdf", ".dat", ".md", ".org"]

        for file in readdir(examples_dir, join = true)
            if isfile(file) && !(basename(file) in keep)
                ext = splitext(file)[2]
                if ext in exts
                    rm(file, force = true)
                end
            end
        end
        println("✓ Cleaned up generated example files")
    end
end

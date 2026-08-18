"""Helpers pertaining to the project structure."""
from std.pathlib import Path


def get_project_name(project_dir: Path) raises -> String:
    """Get the name of the project from the pixi.toml file.

    Args:
        project_dir: the directory to search as the project root

    Returns:
        The name of the project

    Raises:
        If no name is found
    """
    var fh = open(project_dir / "pixi.toml", "r")
    var lines = fh.read().splitlines()

    var package_seen = False
    for line in lines:
        if line.startswith("[package]"):
            package_seen = True
        if package_seen and line.startswith("name"):
            var parts = line.split('"')
            if len(parts) >= 2:
                return String(parts[1])
    raise Error("Unable to find project name in pixi.toml")


def get_module_name(project_name: String) -> String:
    """Convert a Pixi package name to the Mojo module name used by Hat."""
    return project_name.replace("-", "_")

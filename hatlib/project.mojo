"""Helpers pertaining to the project structure."""
from pathlib import Path


fn get_project_name(project_dir: Path) raises -> String:
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
            var quote_idx = line.find('"')
            var name = line[quote_idx + 1 : len(line) - 1]  # -2 for "
            return String(name)
    else:
        raise Error("Unable to find project name in pixi.toml")

"""Walk all files a directory recursively."""
from std.collections import Deque
from std.pathlib import Path

# TODO: make this an iterator


@always_inline
def _no_filter(path: Path) -> Bool:
    return True


def walk_dir[
    *, ignore_dot_files: Bool, filter: fn (Path) -> Bool = _no_filter
](path: Path,) raises -> List[Path]:
    """Walk dirs and collect all files.

    Note that this uses a heap allocated queue instead of recursion.

    Args:
        path: The path to begin the search.

    Returns:
        A list of files in all dirs.

    Parameters:
        ignore_dot_files: If True, skip all dot files and dot dirs.
        filter: A function to apply to each file to filter them out. True == keep.

    """
    var out = List[Path]()
    var to_examine = Deque[Path](path)

    while len(to_examine) > 0:
        var check = to_examine.pop()
        for path in check.listdir():
            var child = check / path

            comptime if ignore_dot_files:
                if String(path).startswith("."):
                    continue

            if child.is_file() and filter(child):
                out.append(child)
            elif child.is_dir():
                to_examine.append(child)
    return out^

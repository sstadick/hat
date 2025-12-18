from os import mkdir, makedirs
from os.path import basename
from pathlib import Path
from collections.deque import Deque
from sys import exit

from hatlib.subprocess import run

from extramojo.io.buffered import BufferedReader
from extramojo.cli.parser import (
    OptParser,
    OptConfig,
    OptKind,
    ParsedOpts,
    SubcommandParser,
    Subcommand,
)

from hatlib.subcommands import HatSubcommand


@always_inline
fn _no_filter(path: Path) -> Bool:
    return True


fn walk_dir[
    *, ignore_dot_files: Bool, filter: fn (Path) -> Bool = _no_filter
](path: Path,) raises -> List[Path]:
    """Walk dirs and collect all files.

    Note that this uses a heap allocated queue instead of recursion.

    Args:
        path: The path to begin the search.

    Returns:
        A list of files in all dirs.

    Paramaters:
        ignore_dot_files: If True, skip all dot files and dot dirs.

    """
    var out = List[Path]()
    var to_examine = Deque[Path](path)

    while len(to_examine) > 0:
        var check = to_examine.pop()
        for path in check.listdir():
            var child = check / path

            @parameter
            if ignore_dot_files:
                if String(path).startswith("."):
                    continue

            if child.is_file() and filter(child):
                out.append(child)
            elif child.is_dir():
                to_examine.append(child)
    return out^


fn get_project_name() raises -> String:
    var fh = open(Path(".") / "pixi.toml", "r")
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


fn is_main(path: Path) -> Bool:
    return basename(path) == "main.mojo"


@fieldwise_init
struct Build(HatSubcommand):
    alias Name = "build"

    @staticmethod
    fn create_subcommand() raises -> Subcommand:
        var parser = OptParser(
            name=Self.Name,
            description="""Build your project.""",
        )
        # parser.add_opt(
        #     OptConfig(
        #         "name",
        #         OptKind.StringLike,
        #         description=(
        #             "The name of the project, also used to create a directory."
        #         ),
        #     )
        # )
        # parser.add_opt(
        #     OptConfig(
        #         "location",
        #         OptKind.StringLike,
        #         description="Location to create the project",
        #         default_value=String("."),
        #     )
        # )
        parser.add_opt(
            OptConfig(
                "debug",
                OptKind.BoolLike,
                description="Create a debug build.",
                is_flag=True,
                default_value=String("False"),
            )
        )
        return Subcommand(parser^)

    @staticmethod
    fn run(var opts: ParsedOpts, read help_message: String) raises:
        if opts.get_bool("help"):
            print(help_message)
            exit(0)

        var debug = opts.get_bool("debug")
        var debug_string = ""
        if debug:
            debug_string = (
                "--debug-level full --optimization-level 0 -D ASSERT=all"
            )

        var project_name = get_project_name()

        var mains = walk_dir[ignore_dot_files=True, filter=is_main](".")

        var build_dir = Path(".") / "target" / "release"
        if debug:
            build_dir = Path(".") / "target" / "debug"
        makedirs(build_dir, exist_ok=True)

        var build_string: String
        if len(mains) > 0:
            if len(mains) != 1:
                raise Error("Conflicting main.mojo files found.")
            var binary = build_dir / project_name
            build_string = "pixi run mojo build {} -o {} {}".format(
                debug_string, String(binary), String(mains[0])
            )
        else:
            var pkg = build_dir / "{}.mojopkg".format(project_name)
            if (Path(".") / project_name).exists():
                build_string = "pixi run mojo package -o {} {}".format(
                    String(pkg), project_name
                )
            elif (Path(".") / "src").exists():
                build_string = "pixi run mojo package -o {} src".format(
                    String(pkg),
                )
            else:
                raise Error("No valid mojopkg project structure found.")

        # print("mains:", mains.__str__())
        # Check for a main.mojo file in [top level, src, <proj_name>]
        # mojo build -o target/release/<proj_name> main.mojo

        # mojo package -o target/release/<proj_name>.mojopkg ./

        # If Debug, turn on symbols tables and asserts, place build in debug target

        var result = run[mimic_tty=True](build_string)
        print(result.stdout)
        if result.returncode != 0:
            raise Error("Build failed: " + build_string)

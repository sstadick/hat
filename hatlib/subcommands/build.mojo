from os import mkdir, makedirs
from os.path import basename
from pathlib import Path
from collections.deque import Deque
from sys import exit, stderr

from hatlib.subprocess import POpenHandle

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
from hatlib.walk_dir import walk_dir
from hatlib.project import get_project_name


fn is_main(path: Path) -> Bool:
    return basename(path) == "main.mojo"


@fieldwise_init
struct Build(HatSubcommand):
    comptime Name = "build"

    @staticmethod
    fn create_subcommand() raises -> Subcommand:
        var parser = OptParser(
            name=Self.Name,
            description="""Build your project.""",
        )
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

        var project_name = get_project_name(Path("."))

        var mains = walk_dir[ignore_dot_files=True, filter=is_main](".")

        var build_dir = Path(".") / "target" / "release"
        if debug:
            build_dir = Path(".") / "target" / "debug"
        makedirs(build_dir, exist_ok=True)

        var build_string: String
        var location: String
        if len(mains) > 0:
            if len(mains) != 1:
                raise Error("Conflicting main.mojo files found.")
            var binary = build_dir / project_name
            build_string = (
                "pixi run --no-progress mojo build {} -o {} {}".format(
                    debug_string, String(binary), String(mains[0])
                )
            )
            location = String(binary)
        else:
            var pkg = build_dir / "{}.mojopkg".format(project_name)
            location = String(pkg)
            if (Path(".") / project_name).exists():
                build_string = (
                    "pixi run --no-progress mojo package -o {} {}".format(
                        String(pkg), project_name
                    )
                )
            elif (Path(".") / "src").exists():
                build_string = (
                    "pixi run --no-progress mojo package -o {} src".format(
                        String(pkg),
                    )
                )
            else:
                raise Error("No valid mojopkg project structure found.")

        print("Running:", build_string, file=stderr)
        var handle = POpenHandle[True](build_string)
        for line in handle:
            print(line)
        print("Build complete:", location, file=stderr)
        var retcode = handle.close()
        if retcode != 0:
            raise Error("Build failed: " + build_string)

        # var result = run[mimic_tty=True](build_string)
        # print(result.stdout)
        # if result.returncode != 0:
        #     raise Error("Build failed: " + build_string)

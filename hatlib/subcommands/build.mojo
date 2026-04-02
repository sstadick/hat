from std.os import mkdir, makedirs
from std.os.path import basename
from std.pathlib import Path
from std.collections.deque import Deque
from std.sys import exit, stderr

from hatlib.subprocess import POpenHandle

from extramojo.io.buffered import BufferedReader
from mojopt.command import Commandable
from mojopt.default import reflection_default
from mojopt.deserialize import MojOptDeserializable, Opt
from mojopt.parser import Parser

from hatlib.subcommands import HatSubcommand
from hatlib.walk_dir import walk_dir
from hatlib.project import get_project_name


def is_main(path: Path) -> Bool:
    return basename(path) == "main.mojo"


@fieldwise_init
struct Build(Commandable, Defaultable, MojOptDeserializable, Writable):
    comptime name = "build"

    var debug: Opt[Bool, help="Create a debug build.", default_value=["False"]]

    @staticmethod
    def description() -> String:
        return """Build your project."""

    def __init__(out self):
        self = reflection_default[Self]()

    def run(self) raises:
        var debug = self.debug.value
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

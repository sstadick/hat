from std.os import makedirs
from std.os.path import basename
from std.pathlib import Path
from std.sys import stderr

from hatlib.subprocess import POpenHandle

from mojopt.command import Commandable
from mojopt.default import reflection_default
from mojopt.deserialize import MojOptDeserializable, Opt

from hatlib.walk_dir import walk_dir
from hatlib.project import get_module_name, get_project_name


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
            debug_string = "--debug-level full --optimization-level 0 -D ASSERT=all"

        var project_name = get_project_name(Path("."))
        var module_name = get_module_name(project_name)

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
            build_string = "pixi run --no-progress mojo build {} -o {} {}".format(
                debug_string, String(binary), String(mains[0])
            )
            location = String(binary)
        else:
            var pkg = build_dir / "{}.mojoc".format(module_name)
            location = String(pkg)
            if (Path(".") / module_name).exists():
                build_string = "pixi run --no-progress mojo precompile {} -o {}".format(
                    module_name, String(pkg)
                )
            elif (Path(".") / "src").exists():
                build_string = "pixi run --no-progress mojo precompile src -o {}".format(
                    String(pkg)
                )
            else:
                raise Error("No valid Mojo package project structure found.")

        print("Running:", build_string, file=stderr)
        var handle = POpenHandle[True](build_string)
        for line in handle:
            print(line, end="")
        var retcode = handle.close()
        if retcode != 0:
            raise Error("Build failed: " + build_string)
        print("Build complete:", location, file=stderr)

        # var result = run[mimic_tty=True](build_string)
        # print(result.stdout)
        # if result.returncode != 0:
        #     raise Error("Build failed: " + build_string)

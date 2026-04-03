from std.os import mkdir, makedirs
from std.pathlib import Path
from std.subprocess import run
from std.sys import exit


from extramojo.io.buffered import BufferedReader
from extramojo.cli.parser import (
    OptParser,
    OptConfig,
    OptKind,
    ParsedOpts,
    SubcommandParser,
    Subcommand,
)
from mojopt.command import Commandable
from mojopt.default import reflection_default
from mojopt.deserialize import MojOptDeserializable, Opt

from hatlib.subcommands import HatSubcommand
from hatlib.subprocess import POpenHandle

comptime NIGHTLY_CHANNEL = "https://conda.modular.com/max-nightly"
comptime STABLE_CHANNEL = "https://conda.modular.com/max"


@fieldwise_init
struct UserInfo(Copyable, Movable):
    var username: String
    var email: String


def pixi_install(project_dir: Path) raises:
    var cmd = String(
        t"pixi install --no-progress --manifest-path {project_dir}/pixi.toml"
    )
    var handle = POpenHandle[True](cmd)
    for line in handle:
        print(line, end="")
    var retcode = handle.close()
    if retcode != 0:
        raise Error("Failed to install deps.")


def get_user_and_email(project_dir: Path) raises -> UserInfo:
    var email = run("git config --global user.email")
    var username = run("git config --global user.name")
    return UserInfo(username^, email^)


def pick_channel(nightly: Bool) -> String:
    if not nightly:
        return STABLE_CHANNEL
    else:
        return NIGHTLY_CHANNEL


def create_lib_structure(project_dir: Path, name: String) raises:
    makedirs(project_dir / name, exist_ok=True)
    touch(project_dir / name / "__init__.mojo")
    var fh = open(project_dir / name / "lib.mojo", "w")
    fh.write_bytes(LIB_TEMPLATE.as_bytes())


def create_bin_structure(project_dir: Path) raises:
    var fh = open(project_dir / "main.mojo", "w")
    fh.write_bytes(MAIN_TEMPLATE.as_bytes())


def touch(path: Path) raises:
    _ = open(path, "a")


def write_gitignore(project_dir: Path) raises:
    var fh = open(project_dir / ".gitignore", "w")
    fh.write_bytes(GITIGNORE_TEMPLATE.as_bytes())


def create_test_structure(project_dir: Path) raises:
    mkdir(project_dir / "tests")
    var fh = open(project_dir / "tests" / "test_example.mojo", "w")
    fh.write_bytes(TEST_TEMPLATE.as_bytes())


# user_info.username, user_info.email, channel, name
def write_pixi_toml(
    project_dir: Path,
    user_info: UserInfo,
    channel: String,
    project_name: String,
) raises:
    var pixi_contents = PIXI_TEMPLATE.format(
        user_info.username, user_info.email, channel, project_name, project_name
    )

    var fh = open(project_dir / "pixi.toml", "w")
    fh.write_bytes(pixi_contents.as_bytes())


@fieldwise_init
struct New(Commandable, Defaultable, MojOptDeserializable, Writable):
    comptime name = "new"

    @staticmethod
    def description() -> String:
        return """Create a new Mojo project.
            For further documentation on Mojo project structure, see https://prefix-dev.github.io/pixi-build-backends/backends/pixi-build-mojo/#project-structure-examples."""

    def __init__(out self):
        self = reflection_default[Self]()

    var project_name: Opt[
        String,
        short="n",
        long="name",
        help="The name of the project, also used to create a directory.",
    ]
    var location: Opt[
        String,
        short="l",
        default_value=["."],
        help="Location to create the project",
    ]
    var nightly: Opt[
        Bool,
        help="Create a project relying on latest nightly mojo.",
        default_value=["False"],
    ]
    var lib: Opt[
        Bool,
        help="Create a project structure for a mojo library.",
        default_value=["False"],
    ]

    def run(self) raises:
        var channel = pick_channel(self.nightly.value)
        var location = Path(self.location.value)

        # Create the directory
        var project_dir = location / self.project_name.value
        mkdir(location / self.project_name.value)
        if self.lib.value:
            mkdir(project_dir / self.project_name.value)

        # Git init and find user info
        _ = run("git init {}".format(String(project_dir)))

        var user_info = get_user_and_email(project_dir)

        # Fill in `pixi.toml` template
        write_pixi_toml(
            project_dir, user_info, channel, self.project_name.value
        )
        write_gitignore(project_dir)

        if self.lib.value:
            create_lib_structure(project_dir, self.project_name.value)
        else:
            create_bin_structure(project_dir)
        create_test_structure(project_dir)
        pixi_install(project_dir)


comptime PIXI_TEMPLATE = """
[workspace]
authors = ["{} <{}>"]
channels = [
    "https://prefix.dev/conda-forge",
    "{}",
    "https://repo.prefix.dev/modular-community",
]
platforms = ["linux-64", "osx-arm64"]
preview = ["pixi-build"]

[package]
name = "{}"
version = "0.1.0"

[package.build]
backend = {{ name = "pixi-build-mojo", version = "0.*", channels = [
    "https://prefix.dev/pixi-build-backends",
    "https://prefix.dev/conda-forge",
    "https://repo.prefix.dev/modular-community",
] }}

[package.host-dependencies]
mojo-compiler = "0.*"

[package.build-dependencies]
mojo-compiler = "0.*"

[package.run-dependencies]
mojo-compiler = "0.*"

[tasks]
r = "mojo run main.mojo"
t = {{ cmd = "sh -c 'find ./tests -name test_*.mojo | xargs -I % mojo run -I . -D ASSERT=all %'" }}


[dependencies]
mojo = "0.*"
{} = {{ path = "." }}
"""

comptime MAIN_TEMPLATE = """
def main() raises:
    print("🎩🪄🐇")
"""

comptime LIB_TEMPLATE = """
def pull_rabbit() -> String:
    return "🐇"
"""

comptime TEST_TEMPLATE = """
from std.testing import assert_equal, TestSuite

def test_example() raises:
    assert_equal("🎩", "🎩")

def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
"""

comptime GITIGNORE_TEMPLATE = """
# pixi environments
.pixi/*
!.pixi/config.toml

# hat
target/*
"""

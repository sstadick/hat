from os import mkdir, makedirs
from pathlib import Path
from subprocess import run
from sys import exit

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
from hatlib.subprocess import POpenHandle

alias NIGHTLY_CHANNEL = "https://conda.modular.com/max-nightly"
alias STABLE_CHANNEL = "https://conda.modular.com/max"


@fieldwise_init
struct UserInfo(Copyable, Movable):
    var username: String
    var email: String


fn pixi_install(project_dir: Path) raises:
    print("running in", project_dir)
    var handle = POpenHandle[True](
        "cd "
        + String(project_dir)
        + " && pixi install --manifest-path "
        + String(project_dir / "pixi.toml")
        + " --no-progress"
    )
    for line in handle:
        print(line)
    var retcode = handle.close()
    if retcode != 0:
        raise Error("Failed to install deps.")


fn get_user_and_email(project_dir: Path) raises -> UserInfo:
    var email = run("git config --global user.email")
    var username = run("git config --global user.name")
    return UserInfo(username^, email^)


fn pick_channel(nightly: Bool) -> String:
    if not nightly:
        return STABLE_CHANNEL
    else:
        return NIGHTLY_CHANNEL


fn create_lib_structure(project_dir: Path, name: String) raises:
    makedirs(project_dir / name, exist_ok=True)
    touch(project_dir / name / "__init__.mojo")
    var fh = open(project_dir / name / "lib.mojo", "w")
    fh.write_bytes(LIB_TEMPLATE.as_bytes())


fn create_bin_structure(project_dir: Path) raises:
    var fh = open(project_dir / "main.mojo", "w")
    fh.write_bytes(MAIN_TEMPLATE.as_bytes())


fn touch(path: Path) raises:
    _ = open(path, "a")


fn write_gitignore(project_dir: Path) raises:
    var fh = open(project_dir / ".gitignore", "w")
    fh.write_bytes(GITIGNORE_TEMPLATE.as_bytes())


fn create_test_structure(project_dir: Path) raises:
    mkdir(project_dir / "tests")
    var fh = open(project_dir / "tests" / "test_example.mojo", "w")
    fh.write_bytes(TEST_TEMPLATE.as_bytes())


# user_info.username, user_info.email, channel, name
fn write_pixi_toml(
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
struct New(HatSubcommand):
    alias Name = "new"

    @staticmethod
    fn create_subcommand() raises -> Subcommand:
        var parser = OptParser(
            name=Self.Name,
            description="""
            Create a new Mojo project.

            For further documentation on Mojo project structure, see https://prefix-dev.github.io/pixi-build-backends/backends/pixi-build-mojo/#project-structure-examples.
            """,
        )
        parser.add_opt(
            OptConfig(
                "name",
                OptKind.StringLike,
                description=(
                    "The name of the project, also used to create a directory."
                ),
            )
        )
        parser.add_opt(
            OptConfig(
                "location",
                OptKind.StringLike,
                description="Location to create the project",
                default_value=String("."),
            )
        )
        parser.add_opt(
            OptConfig(
                "nightly",
                OptKind.BoolLike,
                description="Create a project relying on latest nightly mojo.",
                is_flag=True,
                default_value=String("False"),
            )
        )
        parser.add_opt(
            OptConfig(
                "lib",
                OptKind.BoolLike,
                description="Create a project structure for a mojo library.",
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

        var name = opts.get_string("name")
        var location = Path(opts.get_string("location"))
        var nightly = opts.get_bool("nightly")
        var lib = opts.get_bool("lib")

        var channel = pick_channel(nightly)

        # Create the directory
        var project_dir = location / name
        mkdir(location / name)
        if lib:
            mkdir(project_dir / name)

        # Git init and find user info
        _ = run("cd {} && git init".format(String(project_dir)))

        var user_info = get_user_and_email(project_dir)

        # Fill in `pixi.toml` template
        write_pixi_toml(project_dir, user_info, channel, name)
        write_gitignore(project_dir)

        if lib:
            create_lib_structure(project_dir, name)
        else:
            create_bin_structure(project_dir)
        create_test_structure(project_dir)
        pixi_install(project_dir)


alias PIXI_TEMPLATE = """
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
t = {{ cmd = "script -q /dev/null sh -c 'find ./tests -name test_*.mojo | xargs -I % pixi run mojo run -I . -D ASSERT=all %' 2>&1" }}


[dependencies]
mojo = "0.*"
{} = {{ path = "." }}
"""

alias MAIN_TEMPLATE = """
def main():
    print("🎩🪄🐇")
"""

alias LIB_TEMPLATE = """
fn pull_rabbit() -> String:
    return "🐇"
"""

alias TEST_TEMPLATE = """
from testing import assert_equal, TestSuite

def test_example():
    assert_equal("🎩", "🐇")

def main():
    TestSuite.discover_tests[__functions_in_module()]().run()
"""

alias GITIGNORE_TEMPLATE = """
# pixi environments
.pixi/*
!.pixi/config.toml

# hat
target/*
"""

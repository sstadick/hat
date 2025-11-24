from os import mkdir
from pathlib import Path


from extramojo.cli.parser import (
    OptParser,
    OptConfig,
    OptKind,
    ParsedOpts,
    SubcommandParser,
    Subcommand,
)

from hatlib.subcommands import HatSubcommand


@fieldwise_init
struct New(HatSubcommand):
    alias Name = "new"

    @staticmethod
    fn create_subcommand() raises -> Subcommand:
        var parser = OptParser(
            name=Self.Name, description="Create a new Mojo project."
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
                default=String("."),
            )
        )
        return Subcommand(parser^)

    @staticmethod
    fn run(var opts: ParsedOpts) raises:
        var name = opts.get_string("name")
        var location = Path(opts.get_string("location"))

        # Create the directory
        mkdir(location / name)

        # Fill in `pixi.toml` template
        # TODO: get author name and email from env vars?
        # TODO: get platform from pixi?
        var pixi_contents = PIXI_TEMPLATE.format(name)

        # Write the pixi template to file

        # Write .gitignore

        print("Hi from", Self.Name, " creating ", name)


alias PIXI_TEMPLATE = """
[workspace]
authors = ["Seth Stadick <sstadick@gmail.com>"]
channels = [
    "https://prefix.dev/conda-forge",
    "https://conda.modular.com/max-nightly",
    "https://repo.prefix.dev/modular-community",
]
platforms = ["linux-64", "arm-osx64"]
preview = ["pixi-build"]

[package]
name = "{}"
version = "0.1.0"

[package.build]
backend = { name = "pixi-build-mojo", version = "0.*" }
channels = [
    "https://prefix.dev/pixi-build-backends",
    "https://prefix.dev/conda-forge",
    "https://repo.prefix.dev/modular-community",
]

[package.host-dependencies]
mojo-compiler = "=0.25.7"

[package.build-dependencies]
mojo-compiler = "=0.25.7"

[package.run-dependencies]
mojo-compiler = "=0.25.7"

[tasks]
r = "mojo run main.mojo"

[dependencies]
mojo = "=0.25.7"
"""

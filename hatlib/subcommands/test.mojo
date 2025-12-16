from os import mkdir
from pathlib import Path
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


@fieldwise_init
struct Test(HatSubcommand):
    alias Name = "test"

    @staticmethod
    fn create_subcommand() raises -> Subcommand:
        var parser = OptParser(
            name=Self.Name,
            description="""Run all tests.""",
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
        # parser.add_opt(
        #     OptConfig(
        #         "nightly",
        #         OptKind.BoolLike,
        #         description="Create a project relying on latest nightly mojo.",
        #         is_flag=True,
        #         default_value=String("False"),
        #     )
        # )
        # parser.add_opt(
        #     OptConfig(
        #         "lib",
        #         OptKind.BoolLike,
        #         description="Create a project structure for a mojo library.",
        #         is_flag=True,
        #         default_value=String("False"),
        #     )
        # )
        return Subcommand(parser^)

    @staticmethod
    fn run(var opts: ParsedOpts, read help_message: String) raises:
        if opts.get_bool("help"):
            print(help_message)
            exit(0)

        var result = run[mimic_tty=True]("pixi run t 2>&1")
        print(result.stdout)
        if result.returncode != 0:
            raise Error("Testing failed.")

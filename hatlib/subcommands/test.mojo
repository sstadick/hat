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
        return Subcommand(parser^)

    @staticmethod
    fn run(var opts: ParsedOpts, read help_message: String) raises:
        if opts.get_bool("help"):
            print(help_message)
            exit(0)

        # TODO: Mimic the test command here better instead
        # t = {{ cmd = "script -q /dev/null sh -c 'find ./tests -name test_*.mojo | xargs -I % pixi run mojo run -I . -D ASSERT=all %' 2>&1" }}
        var result = run[mimic_tty=True]("pixi run t 2>&1")
        print(result.stdout)
        if result.returncode != 0:
            raise Error("Testing failed.")

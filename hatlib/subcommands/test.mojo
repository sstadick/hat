from os import mkdir
from pathlib import Path
from sys import exit

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


@fieldwise_init
struct Test(HatSubcommand):
    comptime Name = "test"

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

        # t = {{ cmd = "script -q /dev/null sh -c 'find ./tests -name test_*.mojo | xargs -I % pixi run mojo run -I . -D ASSERT=all %' 2>&1" }}
        var handle = POpenHandle[True](
            "pixi run --no-progress t", capture_stderr_to_stdout=True
        )
        for line in handle:
            print(line)
        var retcode = handle.close()
        if retcode != 0:
            raise Error("Testing failed.")

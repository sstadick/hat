from std.os import mkdir
from std.pathlib import Path
from std.sys import exit

from hatlib.subprocess import POpenHandle

from extramojo.io.buffered import BufferedReader
from mojopt.command import Commandable
from mojopt.default import reflection_default
from mojopt.deserialize import MojOptDeserializable, Opt

from hatlib.subcommands import HatSubcommand


@fieldwise_init
struct Test(Commandable, Defaultable, MojOptDeserializable, Writable):
    comptime name = "test"

    @staticmethod
    def description() -> String:
        return """Run all tests."""

    def run(self) raises:
        # t = {{ cmd = "script -q /dev/null sh -c 'find ./tests -name test_*.mojo | xargs -I % pixi run mojo run -I . -D ASSERT=all %' 2>&1" }}
        var handle = POpenHandle[True](
            "pixi run --no-progress t", capture_stderr_to_stdout=True
        )
        for line in handle:
            print(line, end="")
        var retcode = handle.close()
        if retcode != 0:
            raise Error("Testing failed.")

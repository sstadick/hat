from hatlib.subprocess import POpenHandle

from mojopt.command import Commandable
from mojopt.default import reflection_default
from mojopt.deserialize import MojOptDeserializable


@fieldwise_init
struct Test(Commandable, Defaultable, MojOptDeserializable, Writable):
    comptime name = "test"

    @staticmethod
    def description() -> String:
        return """Run all tests."""

    def run(self) raises:
        var handle = POpenHandle[True]("pixi run --no-progress t", capture_stderr_to_stdout=True)
        for line in handle:
            print(line, end="")
        var retcode = handle.close()
        if retcode != 0:
            raise Error("Testing failed.")

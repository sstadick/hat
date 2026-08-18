from mojopt.command import MojOpt

from hatlib.subcommands.build import Build
from hatlib.subcommands.new import New
from hatlib.subcommands.test import Test


def main() raises:
    var desc = "An accessory build tool for mojo."
    MojOpt[Build, New, Test]().run(toolkit_description=desc)

from sys import exit

from extramojo.cli.parser import OptParser, OptConfig, OptKind, SubcommandParser

from hatlib.subcommands.build import Build
from hatlib.subcommands.new import New
from hatlib.subcommands.test import Test


def main():
    var parser = SubcommandParser(
        name="hat", description="An accessory build tool for mojo."
    )

    parser.add_command(New.create_subcommand())
    parser.add_command(Test.create_subcommand())
    parser.add_command(Build.create_subcommand())

    var cmd_and_opts = parser.parse_sys_args()
    if not cmd_and_opts:
        print(parser.get_help_message())
        exit(1)

    var parsed = cmd_and_opts.value()
    var parsed_cmd = parsed[0]
    var opts = parsed[1].copy()

    if opts.get_bool("help"):
        print(parser.get_help_message())

    if parsed_cmd == New.Name:
        New.run(opts^, parser.commands[parsed_cmd].parser.help_msg())
    elif parsed_cmd == Test.Name:
        Test.run(opts^, parser.commands[parsed_cmd].parser.help_msg())
    elif parsed_cmd == Build.Name:
        Build.run(opts^, parser.commands[parsed_cmd].parser.help_msg())
    else:
        print("Invalid subcommand ", parsed_cmd)
        exit(1)

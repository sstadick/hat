from sys import exit

from extramojo.cli.parser import OptParser, OptConfig, OptKind, SubcommandParser

from hatlib.subcommands.new import New


def main():
    var parser = SubcommandParser(
        name="hat", description="An accessory build tool for mojo."
    )

    var commands = {New.Name: New.run}
    parser.add_command(New.create_subcommand())

    var cmd_and_opts = parser.parse_sys_args()
    if not cmd_and_opts:
        print(parser.get_help_message())
        exit(1)

    var parsed = cmd_and_opts.value()
    var parsed_cmd = parsed[0]
    var opts = parsed[1].copy()

    var runner = commands.get(parsed_cmd)
    if not runner:
        print("Invalid subcommand ", parsed_cmd)
        exit(1)

    runner.value()(opts^)

    print("Hello world")

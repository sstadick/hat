from extramojo.cli.parser import ParsedOpts, Subcommand


trait HatSubcommand:
    comptime Name: String

    @staticmethod
    def create_subcommand() raises -> Subcommand:
        ...

    @staticmethod
    def run(var opts: ParsedOpts, read help_message: String) raises:
        ...

from extramojo.cli.parser import ParsedOpts, Subcommand


trait HatSubcommand:
    alias Name: String

    @staticmethod
    fn create_subcommand() raises -> Subcommand:
        ...

    @staticmethod
    fn run(var opts: ParsedOpts) raises:
        ...

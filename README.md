# cogctl

CLI admin interface for Cog.

## Compiling

        mix escript

## Examples

        > cogctl bootstrap -s
        The system has been bootstrapped.
        > cogctl --help
        Usage: cogctl [bootstrap | bundles]

        cogctl <action> --help will display action specific help information.
        > cogctl bootstrap --help
        Usage: cogctl bootstrap [--help] [-n [<node>]] [-s]

        --help        Displays brief help
        -n, --node    Set name of remote bot VM [default: loop_dev@localhost]
        -s, --status  Queries Cog's current bootstrap status

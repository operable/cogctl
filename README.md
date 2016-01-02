# cogctl

CLI admin interface for Cog.

## Compiling

        mix escript

## Examples

        > cogctl bootstrap -s
        bootstrapped
        > cogctl --help
        Usage: cogctl [bootstrap | profiles]

        cogctl <action> --help will display action specific help information.
        > cogctl bootstrap --help
        Usage: cogctl bootstrap [-?] [-h [<host>]] [-p [<port>]] [-u] [--pw]
        [--profile [<profile>]] [-s]

        -?, --help    Displays this brief help
        -h, --host    Host name or network address of the target Cog instance
        [default: localhost]
        -p, --port    REST API port of the target Cog instances [default: 4000]
        -u, --user    REST API user
        --pw          REST API password
        --profile     $HOME/.cogctl profile to use [default: undefined]
        -s, --status  Queries Cog's current bootstrap status

        > cogctl profiles
        Profile: localhost
        User: admin
        Password: ***
        URL: https://localhost:4000

        >

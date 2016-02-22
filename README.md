# cogctl

CLI admin interface for [Cog](https://github.com/operable/cog).

## Compiling

        mix escript

## Examples

        > cogctl bootstrap -s
        bootstrapped
        > cogctl --help
        Usage: cogctl	[bootstrap | profiles | bundles | bundles info | bundles delete |
                         bundles enable | bundles disable | users | users info | users create | users update |
                         users delete | groups | groups info | groups create | groups update | groups delete |
                         groups add | groups remove | roles | roles create | roles update | roles delete |
                         roles grant | roles revoke | rules | rules create | rules delete | permissions |
                         permissions create | permissions delete | permissions grant | permissions revoke |
                         chat-handles | chat-handles create | chat-handles delete]

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

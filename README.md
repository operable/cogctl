# cogctl

CLI admin interface for [Cog](https://github.com/operable/cog).

## Setting up

### Prerequisites

To compile and run cogctl you will need both Elixir and Erlang installed. If you're on osx the easiest way to install is through homebrew, `brew install elixir`. Elixir runs in the Erlang VM and therefore Erlang is required. If you're installing with homebrew, don't worry, it should pull Erlang as a dependency and install everything for you. Cogctl has been tested with Erlang version 18.3.2 and Elixir version 1.3.1.

To build cogctl you'll also need hex and rebar:

    mix local.hex --force
    mix local.rebar --force

### Compiling

After getting all the prerequisites out of the way you can pull cogctl's deps and compile.

    mix escript

This creates an escript called **cogctl** in the current directory.

### Configuring

After compiling you will need to configure cogctl to connect to Cog. Cog connection data is defined as a profile and is stored in a configuration file, **.cogctl**, that is located in your home directory by default. There can be multiple profiles defined for connecting to different instances of Cog.

If you're connecting to a fresh install of Cog that has yet to be bootstrapped you only need two bits of information: the Cog host and port.

Then run:

    cogctl bootstrap --host $COG_HOST --port $COG_PORT

Replacing $COG_HOST and $COG_PORT with appropriate values.

Bootstrapping creates an admin user and returns the login info to cogctl. Cogctl will automatically create the **.cogctl** configuration file and place it in your home directory.

If you're connecting to an instance of Cog that has already been bootstrapped then in addition to the host and port you will also need your Cog user name and password.

Then to create a profile:

    cogctl profiles create $PROFILE_NAME --host $COG_HOST --port $COG_PORT --rest-user $COG_USER_NAME --rest-password $COG_PASSWORD

Note: If you prefer not to create a profile, or you want to override something, you can just use the _host_, _port_, _rest-user_ and _rest-password_ flags. They are available for every subcommand in cogctl.

Note: If you are connecting to Cog over https then you will also need to pass the _secure_ flag.

## Examples

        > cogctl bootstrap -s
        bootstrapped
        > cogctl --help
        Usage: cogctl   [bootstrap | profiles | profiles create | bundle | bundle versions |
                        bundle info | bundle install | bundle uninstall | bundle enable | bundle disable | dynamic-config |
                        dynamic-config create | dynamic-config delete | dynamic-config info | users | users info | users create |
                        users update | users delete | users request password reset | users reset password | groups | groups info |
                        groups create | groups rename | groups delete | groups add | groups remove | relays |
                        relays info | relays create | relays enable | relays disable | relays update | relays delete |
                        relay-groups | relay-groups info | relay-groups create | relay-groups add | relay-groups remove | relay-groups assign |
                        relay-groups unassign | relay-groups delete | roles | roles info | roles create | roles rename |
                        roles delete | roles grant | roles revoke | rules | rules create | rules delete |
                        permissions | permissions create | permissions delete | permissions grant | permissions revoke | triggers |
                        triggers create | triggers delete | triggers disable | triggers enable | triggers info | triggers update |
                        chat-handles | chat-handles create | chat-handles delete]

               cogctl <action> --help will display action specific help information.

        > cogctl bootstrap --help
        Usage: cogctl bootstrap [-s] [-? [<help>]] [-h [<host>]] [-p [<port>]]
                                [-s [<secure>]] [-U [<rest_user>]]
                                [-P [<rest_password>]] [-i [<stdin>]]
                                [--config-file [<config_file>]]
                                [--profile [<profile>]]

          -s, --status         Queries Cog's current bootstrap status
          -?, --help           Displays this brief help [default: false]
          -h, --host           Host name or network address of the target Cog
                               instance [default: undefined]
          -p, --port           REST API port of the target Cog instances [default:
                               undefined]
          -s, --secure         Use HTTPS to connect to Cog [default: undefined]
          -U, --rest-user      REST API user [default: undefined]
          -P, --rest-password  REST API password [default: undefined]
          -i, --stdin          Read from stdin [default: false]
          --config-file        Path to configuration file to use [default:
                               /Users/mpeck/.cogctl]
          --profile            Profile from configuration file to use [default:
                               undefined]

        > cogctl profiles
        Profile: localhost
        User: admin
        Password: ***
        URL: https://localhost:4000
        >

## Filing Issues

cogctl issues are tracked centrally in [Cog's](https://github.com/operable/cog/issues) issue tracker.

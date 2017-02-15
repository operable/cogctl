Feature: Provide basic help

  Scenario: executing cogctl with no arguments or options at all returns help
    When I successfully run `cogctl`
    Then the output should contain:
      """
      Usage: cogctl [OPTIONS] COMMAND [ARGS]...

        Manage Cog via its REST API on the command line.

      Options:
        -c, --config-file PATH  Path to an INI-formatted configuration file
                                [default: ~/.cogctl]
        -p, --profile TEXT      The profile within the config file to use
        -u, --url TEXT          Override API URL root to use, e.g.
                                'https://127.0.0.0:4000'
        -U, --user TEXT         Override account to authenticate against the API
        -P, --password TEXT     Override password to authenticate against the API
        -v, --verbose           Be verbose
        --help                  Show this message and exit.

      Commands:
        bootstrap
        bundle       Manage command bundles and their config.
        chat-handle  Manage user chat handles.
        group        Manage Cog user groups.
        permission   Manage permissions.
        profile      Manage Cog profiles.
        relay        Manage relays.
        relay-group  Manage relay groups.
        role         Manage roles and role grants.
        rule         Manage rules.
        shell        Starts a interactive cogctl session.
        token        Generate a Cog API token.
        trigger      Create, edit, delete, and view Cog triggers.
        user         Manage Cog users.
        version      Display version and build information.
      """

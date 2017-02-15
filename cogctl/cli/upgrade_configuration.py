import click


@click.command(name="upgrade-configuration")
@click.pass_obj
def upgrade_configuration(state):
    """Upgrade old configuration files.

    Instead of defining separate "host", "port", and "secure" values
    for a Cog server's API endpoint, all three are consolidated into a
    single "url" value.

    All entries from the specified configuration file are updated and
    then written back out to the same file.
    """

    config = state.configuration

    for p in config.profiles():
        config.update_profile(p)

    config.write()

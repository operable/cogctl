import click
from click_didyoumean import DYMGroup


@click.group(invoke_without_command=True, cls=DYMGroup)
@click.pass_context
def profile(ctx):
    """Manage Cog profiles.

    If invoked without a subcommand, lists all the profiles in the
    config file.

    """
    if ctx.invoked_subcommand is None:
        config = ctx.obj.configuration

        default = config.default_profile_name()
        names = config.profiles()
        for profile_name in names:
            profile = config.profile(profile_name)
            if profile_name == default:
                click.echo("Profile: %s (default)" % profile_name)
            else:
                click.echo("Profile: %s" % profile_name)
            click.echo("User: %s" % profile['user'])
            click.echo("URL: %s" % profile['url'])
            click.echo()


# TODO: validate that name isn't already taken
# TODO: use a password_option instead
@profile.command()
@click.argument("name")
@click.option("--host", default="localhost", show_default=True)
@click.option("--port", default=4000, show_default=True)
@click.option("--secure", is_flag=True, default=False,
              help="Use HTTPS?", show_default=True)
@click.option("--rest-user", required=True)
@click.option("--rest-password", required=True)
@click.pass_obj
def create(state, name, host, port, secure, rest_user, rest_password):
    """
    Add a new profile to a `.cogctl` file.
    """
    state.configuration.add(name, {"host": host,
                                   "port": port,
                                   "secure": secure,
                                   "user": rest_user,
                                   "password": rest_password})
    state.configuration.write()

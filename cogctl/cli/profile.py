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


# TODO: validate that name isn't already taken?
# TODO: use a password_option instead?
@profile.command()
@click.argument("name")
@click.argument("url")
@click.argument("user")
@click.argument("password")
@click.pass_obj
def create(state, name, url, user, password):
    """
    Add a new profile to a the configuration file.
    """
    state.configuration.add(name, {"url": url,
                                   "user": user,
                                   "password": password})
    state.configuration.write()

import click
from click_didyoumean import DYMGroup
import click_repl
from prompt_toolkit.history import FileHistory
import cogctl.cli.config as config
import os
from cogctl.cli.bootstrap import bootstrap
from cogctl.cli.bundle.main import bundle
from cogctl.cli.chat_handle import chat_handle
from cogctl.cli.group import group
from cogctl.cli.permission import permission
from cogctl.cli.profile import profile
from cogctl.cli.relay.group import relay_group
from cogctl.cli.relay.relay import relay
from cogctl.cli.role import role
from cogctl.cli.rule import rule
from cogctl.cli.state import State
from cogctl.cli.token import token
from cogctl.cli.trigger import trigger
from cogctl.cli.user import user
from cogctl.cli.version import version


# List of all top level commands
COMMANDS = [bootstrap, bundle, chat_handle, group, permission, profile,
            relay, relay_group, role, rule, token, trigger, user, version]


@click.group(cls=DYMGroup)
@click.option("--config-file", "-c", type=click.Path(exists=False),
              default="~/.cogctl", envvar='COGCTL_CONFIG_FILE',
              help="Path to an INI-formatted configuration file",
              show_default=True)
@click.option("--profile", "-p",
              envvar='COGCTL_DEFAULT_PROFILE',
              help="The profile within the config file to use")
@click.option("--url", "-u", show_default=True,
              help="Override API URL root to use, "
              "e.g. 'https://127.0.0.0:4000'")
@click.option("--user", "-U", show_default=True,
              help="Override account to authenticate against the API")
@click.option("--password", "-P", show_default=True,
              help="Override password to authenticate against the API")
@click.option("--verbose", "-v", count=True,
              help="Be verbose")
@click.pass_context
def cli(ctx, config_file, profile, url, user, password, verbose):
    """
    Manage Cog via its REST API on the command line.
    """

    state = State()

    config_file = os.path.abspath(os.path.expanduser(config_file))
    state.config_file = config_file
    state.verbosity = verbose

    if os.path.isfile(config_file):
        try:
            state.configuration = config.read_config(config_file)
        except KeyError:
            raise click.BadParameter("The configuration file '%s' does not "
                                     "specify a default profile, and is thus "
                                     "invalid" % config_file,
                                     param_hint=['--config-file'])

    if profile:
        if state.configuration:
            profile_data = state.configuration.get(profile)
            if profile_data:
                state.profile = state.configuration[profile]
            else:
                raise click.BadParameter("Profile '%s' was not found in "
                                         "configuration file '%s'"
                                         % (profile, config_file),
                                         param_hint=['--profile'])
        else:
            raise click.BadParameter("If you specify a profile, the "
                                     "configuration file must exist",
                                     param_hint=['--config-file', '--profile'])
    else:
        if state.configuration:
            profile = next((p for p in state.configuration.values()
                            if p['default']))
            state.profile = profile

    if url:
        state.profile["url"] = url

    if user:
        state.profile["user"] = user

    if password:
        state.profile["password"] = password

    ctx.obj = state


@cli.command()
def shell():
    """
    Starts a interactive cogctl session.

    Command history is stored at $HOME/.cogctl_history

    NOTE: Command bundle execution is NOT supported.
    """
    prompt_kwargs = {
        'history': FileHistory(os.path.expandvars("$HOME/.cogctl_history"))
    }
    click_repl.repl(click.get_current_context(), prompt_kwargs=prompt_kwargs)


for c in COMMANDS:
    cli.add_command(c)

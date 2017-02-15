import click
import cogctl
import cogctl.api


@click.command()
@click.pass_obj
@cogctl.error_handler
def token(state):
    """
    Generate a Cog API token.

    Other `cogctl` commands will retrieve their own tokens; this
    command is provided as a convenience for any other token-related
    needs you may have.
    """
    click.echo(state.api.token())

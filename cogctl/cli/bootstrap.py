import click
import cogctl
from cogctl.api import Api
from urllib.parse import urlparse


@click.command()
@click.argument("url", required=True, default="http://localhost:4000")
@click.option("--status", is_flag=True, default=False,
              help="Query the bootstrap status, instead of bootstrapping",
              show_default=True)
@click.pass_obj
@cogctl.error_handler
def bootstrap(state, url, status):
    """Bootstrap a Cog server.

    If no URL is supplied, the command defaults to operating on
    http://localhost:4000.

    Following a successful bootstrapping, the returned password and
    user information are added to cogctl's configuration file as a new
    profile, named for the hostname of the server being
    bootstrapped. If this is the first profile to be added to this
    configuration file, it will be marked as the default.

    """

    api = Api(url)

    if status:
        result = api.bootstrap_status()
        if result['bootstrap']['bootstrap_status']:
            click.echo("Status: bootstrapped")
        else:
            click.echo("Status: Not bootstrapped")
    else:
        click.echo("Bootstrapping the server")

        result = api.bootstrap()

        if result.get("errors"):
            raise click.ClickException(result["errors"]["bootstrap"])
        else:
            user = result['bootstrap']['username']
            password = result['bootstrap']['password']
            profile_name = urlparse(url).hostname

            state.configuration.add(profile_name, {"url": url,
                                                   "user": user,
                                                   "password": password})
            state.configuration.write()

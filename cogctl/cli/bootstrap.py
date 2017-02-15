import click
import cogctl
from cogctl.api import Api
from cogctl.cli.config import add_profile


@click.command()
@click.option("--status", is_flag=True, default=False,
              help="Query the bootstrap status, instead of bootstrapping",
              show_default=True)
@click.option("--host", default="localhost", show_default=True)
@click.option("--port", default=4000, show_default=True)
@click.option("--secure", is_flag=True, default=False,
              help="Use HTTPS?", show_default=True)
@click.pass_obj
@cogctl.error_handler
def bootstrap(state, status, host, port, secure):
    # TODO: unify this with the rest of the profile code
    if secure:
        protocol = "https"
    else:
        protocol = "http"

    api_root = "%s://%s:%s" % (protocol, host, port)

    api = Api(api_root)

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

            add_profile(state.config_file, host, {"host": host,
                                                  "port": port,
                                                  "secure": secure,
                                                  "user": user,
                                                  "password": password})

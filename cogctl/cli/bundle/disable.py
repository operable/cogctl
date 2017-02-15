import click
import cogctl
import cogctl.cli.bundle.validators as validators


@click.command()
@click.argument("bundle", callback=validators.validate_bundle_name,
                required=True, metavar="NAME")
@cogctl.error_handler
@click.pass_obj
def disable(state, bundle):
    """Disable a bundle by name.
    """

    enabled_version = bundle['enabled_version']
    if enabled_version:
        resp = state.api.disable_bundle(enabled_version)
        click.echo("Disabled %s" % resp['name'])
    else:
        click.echo("%s was already disabled" % bundle['name'])

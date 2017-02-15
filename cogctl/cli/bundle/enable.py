import click
import cogctl
import cogctl.cli.bundle.validators as validators
from semantic_version import Version


def check_version(ctx, param, value):
    bundle = ctx.params['bundle']
    if value:
        value = validators.ensure_semver(value)
    else:
        value = max((v['version'] for v in bundle['versions']),
                    key=Version)

    version = next((v for v in bundle['versions']
                    if v['version'] == value), None)

    # TODO: I think we can get all we need from the bundle, without
    # having to make another API call here
    if version:
        return ctx.obj.api.bundle_version(bundle['id'], version['id'])
    else:
        raise click.BadParameter(("No version %s found for %s" %
                                  (value, bundle['name'])))


@click.command()
@click.argument("bundle", callback=validators.validate_bundle_name,
                required=True, metavar="NAME")
@click.argument("version", callback=check_version, required=False)
@cogctl.error_handler
@click.pass_obj
def enable(state, bundle, version):
    """Enable the specified version of the bundle.

    If no version is given, the latest installed version (by standard
    semantic version ordering) will be enabled.

    If any version of this bundle is currently enabled, it will be
    disabled in the process.
    """
    resp = state.api.enable_bundle_version(version)
    click.echo("Enabled %s %s" % (resp['name'], resp['enabled_version']))

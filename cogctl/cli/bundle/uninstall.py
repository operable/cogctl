import click
import cogctl
import cogctl.cli.bundle.validators as validators


def check_version(ctx, param, value):
    """Requires that a "bundle" parameter has already been processed
    before running.

    """

    if not value:
        return value

    bundle = ctx.params['bundle']
    value = validators.ensure_semver(value)

    # We want to be able to delete incompatible versions by version
    version = next((v for v in (bundle['versions'] +
                                bundle.get('incompatible_versions', []))
                    if v['version'] == value), None)

    if not version:
        raise click.BadParameter(("No version %s found for %s" %
                                  (value, bundle['name'])))

    enabled_version = bundle['enabled_version']
    if enabled_version and enabled_version['version'] == value:
        raise click.BadParameter("Cannot uninstall enabled version. "
                                 "Please disable the bundle first")

    return ctx.obj.api.bundle_version(bundle['id'], version['id'])


@click.command()
@click.argument("bundle", callback=validators.validate_bundle_name,
                required=True, metavar="NAME")
# TODO: Hrmm... version can be multiple :/
@click.argument("version", callback=check_version, required=False)
@click.option("--clean", "-c", is_flag=True, default=False,
              help="Uninstall all disabled bundle versions")
@click.option("--incompatible", "-x", is_flag=True, default=False,
              help="Uninstall all incompatible versions of the bundle")
@click.option("--all", "-a", is_flag=True, default=False,
              help="Uninstall all versions of the bundle")
@cogctl.error_handler
@click.pass_obj
def uninstall(state, bundle, version, clean, incompatible, all):
    """Uninstall bundles.
    """
    if version and (clean or incompatible or all):
        raise click.BadParameter(
            "Do not give a version if using --incompatible, --all, --clean",
            param_hint=["version"])

    if bundle['enabled_version'] and all:
        raise click.BadParameter(
            ("%s %s is currently enabled. Please disable the bundle first." %
             (bundle['name'], bundle['enabled_version']['version'])),
            param_hint=["bundle"])

    # This duplicates the Elixir cogctl behavior; these are all
    # mutually exclusive actions
    if incompatible:
        # The "incompatible" key is only added to incompatible
        # bundles, so we have to use get() here.
        versions = [v for v in state.api.bundle_versions(bundle)
                    if v.get("incompatible", False)]
    elif all:
        versions = state.api.bundle_versions(bundle)
    elif clean:
        if bundle['enabled_version']:
            enabled_version = bundle['enabled_version']['version']
        else:
            enabled_version = None

        versions = (v for v in state.api.bundle_versions(bundle)
                    if v['version'] != enabled_version)

    elif version:
        versions = [version]
    else:
        # Ideally, this could be handled in a validator callback, but
        # I don't think it's possible
        raise click.BadParameter(
            "Can't uninstall without specifying a version, "
            "or --incompatible, --all, --clean",
            param_hint=["version"])

    if versions:
        for v in versions:
            state.api.uninstall_bundle(v)
            # TODO: only if verbose?
            click.echo("Uninstalled %s %s" % (v['name'], v['version']))
    else:
        click.echo("Nothing to uninstall")

import click
from click_didyoumean import DYMGroup
import cogctl
from operator import itemgetter
from semantic_version import Version
from cogctl.cli.bundle.disable import disable
from cogctl.cli.bundle.enable import enable
from cogctl.cli.bundle.info import info
from cogctl.cli.bundle.install import install
from cogctl.cli.bundle.uninstall import uninstall
from cogctl.cli.bundle.versions import versions
from cogctl.cli.bundle.config import config


@click.group(invoke_without_command=True, cls=DYMGroup)
@click.option("--enabled", "-e", is_flag=True, default=False,
              help="List only enabled bundles")
@click.option("--disabled", "-d", is_flag=True, default=False,
              help="List only disabled bundles")
@click.option("--verbose", "-v", is_flag=True, default=False,
              help="Display additional bundle details")
@click.pass_context
@cogctl.error_handler
def bundle(ctx, enabled, disabled, verbose):
    """Manage command bundles and their config.

    If no subcommand is given, lists all bundles installed, and their
    currently enabled version, if any.
    """
    if ctx.invoked_subcommand is None:

        bundles = ctx.obj.api.bundles()

        if enabled and disabled:
            # This is the same as if no options were given
            pass
        else:
            if enabled:
                bundles = [b for b in bundles
                           if b.get("enabled_version", None)]
            if disabled:
                bundles = [b for b in bundles
                           if b.get("enabled_version", None) is None]

        bundles = [_munge_bundle(b, verbose)
                   for b in sorted(bundles, key=itemgetter("name"))]

        if verbose:
            keys = ["name", "enabled_version",
                    "installed_versions", "bundle_id"]
        else:
            keys = ["name", "enabled_version"]

        table = cogctl.cli.table.render_dicts(bundles, keys)
        click.echo(table)


def _munge_bundle(api_bundle, verbose):
    enabled = api_bundle.get("enabled_version", None)
    base = {"name": api_bundle["name"],
            "enabled_version": enabled["version"] if enabled else "(disabled)"}

    # TODO: This does not do anything with incompatible bundles
    if verbose:
        versions = sorted([v["version"] for v in api_bundle["versions"]],
                          key=Version)

        base["installed_versions"] = ", ".join(versions)
        base["bundle_id"] = api_bundle["id"]

    return base


bundle.add_command(disable)
bundle.add_command(enable)
bundle.add_command(info)
bundle.add_command(install)
bundle.add_command(uninstall)
bundle.add_command(versions)
bundle.add_command(config)

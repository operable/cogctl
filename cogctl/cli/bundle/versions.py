import click
import cogctl
import cogctl.cli.table
from operator import itemgetter
from semantic_version import Version
import cogctl.cli.bundle.validators as validators


@click.command()
@click.argument("bundle", callback=validators.validate_bundle_name,
                required=False, metavar="NAME")
@click.option("--incompatible", "-x", is_flag=True, default=False,
              help="List only incompatible bundle versions")
@click.pass_obj
def versions(state, bundle, incompatible):
    """List installed bundle versions.

    If no bundle name is given, all versions of all bundles are
    listed, along with their status ("Enabled", "Disabled",
    "Incompatible")

    Alternatively, if a bundle name is supplied, only versions of that
    bundle are shown.

    In either case, supplying the `--incompatible` option restricts
    the listing to only incompatible versions.
    """
    if bundle:
        bundles = [bundle]
    else:
        bundles = sorted(state.api.bundles(), key=itemgetter("name"))

    # We can assemble all the data we currently need using the single
    # top-level bundle API call. The previous cogctl implementation
    # used multiple API calls, and we may need to do that later if we
    # need more in-depth information.
    versions = [v for b in bundles for v in _munge_versions(b)]

    if incompatible:
        versions = [v for v in versions if v["status"] == "Incompatible"]

    table = cogctl.cli.table.render_dicts(versions,
                                          ["bundle", "version", "status"])
    click.echo(table)


def _munge_versions(api_bundle):
    name = api_bundle['name']

    compatible = api_bundle['versions']
    incompatible = api_bundle.get('incompatible_versions', [])

    enabled_version = None
    if api_bundle['enabled_version']:
        enabled_version = api_bundle['enabled_version']['version']

    compatible = [{"bundle": name,
                   "version": v['version'],
                   "status": "Enabled" if v['version'] == enabled_version else "Disabled"}  # noqa: E501
                  for v in compatible]

    incompatible = [{"bundle": name,
                     "version": v['version'],
                     "status": "Incompatible"}
                    for v in incompatible]

    return sorted(compatible + incompatible,
                  key=lambda v: Version(v["version"]))

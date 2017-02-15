import click
import cogctl
import cogctl.bundle
import cogctl.cli.bundle.validators as validators
import os
from cogctl.cli.util import raise_if_not_all_present


def check_bundle_or_path(ctx, param, value):
    """Validate the bundle value.

    A bundle can be specified as one of 3 types of values:

    * "-", for standard input. The user streams the contents of a
      config.yaml file in from somewhere else.
    * a bare bundle name. This will be resolved in the Bundle
      Warehouse (https://warehouse.operable.io)
    * a file path. This is a path to a config.yaml file on the local
      filesystem. It must be an existing, readable file.

    A bundle name is differentiated from a file path by not having an
    extension, and not "looking like a path". Thus "foobar" would be a
    bundle name, but "/dir/foobar", "foobar.yaml", etc. would be
    interpreted as paths.

    Valid results are returned as 2-tuples. The first element is the
    actual value, while the second denotes what "type" of value it is
    (either "registry" or "path", which includes stdin) to facilitate
    processing later on.
    """

    base = os.path.basename(value)
    (name, ext) = os.path.splitext(base)

    # Value must be an existing file path, or "-", or a single name
    if value == "-":
        return (value, "path")
    elif name == value:
        # Treat it like a bare bundle name for retrieval from
        # warehouse
        return (name, "registry")
    else:
        # Treat it like a file path
        path_checker = click.types.Path(exists=True,
                                        file_okay=True,
                                        dir_okay=False,
                                        readable=True,
                                        allow_dash=False)
        return (path_checker.convert(value, param, ctx), "path")


def check_version(ctx, param, value):
    """Only allow a value to be set if the bundle is coming from
    Warehouse.

    Depends on the bundle_or_path argument having already been
    validated.
    """
    (bundle_info, bundle_type) = ctx.params['bundle_or_path']
    if bundle_type == "path" and value:
        raise click.BadParameter("Versions may only be set for bundles "
                                 "loaded from the Bundle Warehouse "
                                 "(https://warehouse.operable.io)")

    if bundle_type == "registry" and value:
        value = validators.ensure_semver(value)

    # If a version is unspecified, set it to "latest"
    if bundle_type == "registry" and not value:
        value = "latest"

    return value


def check_relay_groups(ctx, param, value):
    """Previously (in Elixir) we treated --relay-groups as a single,
    optionally comma-delimited string to specify mulitple relay
    groups. We can now have repeating values instead. To stay as
    backward compatible as we can, we'll split any comma-delimited
    strings and create one flattened list.

    Thus, the following are all equivalent:

    * `-r foo -r bar -r baz`
    * `-r foo,bar,baz`
    * `-r foo -r bar,baz

    Additionally, if any relay groups are given, we'll verify they
    actually exist; if all are real, we return their API
    representations for use later. If any don't exist, we'll just stop
    all processing right here.
    """
    names = [g for gs in value for g in gs.split(",")]

    if names:
        groups = ctx.obj.api.relay_groups(*names)
        raise_if_not_all_present(names, groups,
                                 "The following relay groups do not exist: {}")
        return groups
    else:
        return []


@click.command()
@click.argument("bundle_or_path", callback=check_bundle_or_path,
                required=True)
@click.argument("version", callback=check_version, required=False)
@click.option("--enable", "-e", is_flag=True, default=False,
              help="Automatically enable a bundle after installing?",
              show_default=True)
@click.option("--force", "-f", is_flag=True, default=False,
              help="Install even if a bundle with the same version "
              "is already installed. Applies only to bundles installed "
              "from a file, and not from the Warehouse bundle registry. "
              "Use this to shorten iteration cycles in bundle development.",
              show_default=True)
@click.option("--relay-group", "-r", multiple=True,
              callback=check_relay_groups,
              help="Relay group to assign the bundle to. "
              "Can be specified multiple times.")
@click.option("--templates", "-t", required=False,
              type=click.Path(exists=True, file_okay=False,
                              dir_okay=True, readable=True),
              help="Path to templates directory. Template bodies will be "
              "inserted into the bundle configuration prior to uploading. "
              "This makes it easier to manage complex templates.")
@cogctl.error_handler
@click.pass_obj
def install(state, bundle_or_path, version, enable, force, relay_group, templates):  # noqa: E501
    """Install a bundle.

    Bundles may be installed from either a file (i.e., the
    `config.yaml` file of a bundle), or from Operable's Warehouse
    bundle registry (https://warehouse.operable.io).

    When installing from a file, you may either give the path to the
    file, as in:

        cogctl bundle install /path/to/my/bundle/config.yaml

    or you may give the path as `-`, in which case standard input is
    used:

        cat config.yaml | cogctl bundle install -

    When installing from the bundle registry, you should instead
    provide the name of the bundle, as well as an optional version to
    install. No version means the latest will be installed.

        cogctl bundle install cfn

        cogctl bundle install cfn 0.5.13

    """

    (bundle_info, bundle_type) = bundle_or_path

    # Ideally, I'd like to do these validations as callbacks on the
    # options, but I think that options get parsed before args,
    # meaning that they won't have access to what kind of bundle is
    # being installed until we get here.
    if bundle_type == "registry" and force:
        raise click.BadParameter("Cannot force-install bundles from "
                                 "the Bundle Warehouse "
                                 "(https://warehouse.operable.io)",
                                 param_hint=["--force", "-f"])

    # This one is a little annoying as it is, because we'll only get
    # down to here if the user specified a templates directory that
    # actually exists. Whether it exists or not, we just want to say
    # "no" if they're trying to install from the registry.
    if bundle_type == "registry" and templates:
        raise click.BadParameter("Cannot add templates to bundles installed "
                                 "from the Bundle Warehouse "
                                 "(https://warehouse.operable.io)",
                                 param_hint=["--templates", "-t"])

    api = state.api

    if bundle_type == "path":
        with click.open_file(bundle_info) as f:
            content = f.read()

        bundle_cfg = cogctl.bundle.from_yaml(content)
        if templates and os.path.isdir(templates):
            bundle_cfg = cogctl.bundle.add_templates(bundle_cfg,
                                                     templates)
        # TODO: Need to validate once we have JSON schema in place,
        # and add a test with invalid config
        bundle_version = api.install_bundle(bundle_cfg, force)

    elif bundle_type == "registry":
        bundle_version = api.install_bundle_from_registry(bundle_info, version)

    else:  # pragma: no cover
        # NOTE: shouldn't ever get here
        msg = "Internal error: Unknown bundle type '%s'!" % bundle_type
        raise Exception(msg)

    bundle_id = bundle_version['bundle_version']['bundle_id']
    bundle_name = bundle_version['bundle_version']['name']
    installed_version = bundle_version['bundle_version']['version']

    click.echo("Installed %s version %s" % (bundle_name, installed_version))

    for group in relay_group:
        resp = api.assign_bundles_to_group(group, [{"id": bundle_id}])
        msg = "Assigned %s to relay group %s" % (bundle_name,
                                                 resp['name'])
        click.echo(msg)

    if enable:
        resp = api.enable_bundle_version(bundle_version['bundle_version'])
        click.echo("Enabled %s version %s" % (resp['name'],
                                              resp['enabled_version']))

import click
from click_didyoumean import DYMGroup
import cogctl
import cogctl.cli.bundle.validators as bundle_validators
import cogctl.cli.output as output
import yaml


def check_layer_name(ctx, param, value):
    if value == "base":
        return ["base", "config"]
    elif (value.startswith("user/") or value.startswith("room/")):
        return value.split("/", maxsplit=2)
    else:
        raise click.BadParameter("Must specify layer as 'base', "
                                 "'room/$NAME', or 'user/$NAME'")


def check_layer(ctx, param, value):
    layer, name = check_layer_name(ctx, param, value)
    bundle = ctx.params["bundle"]

    try:
        return ctx.obj.api.dynamic_config(bundle, layer, name)
    except StopIteration:
        raise click.BadParameter(
            "Layer '{}' not found for bundle '{}'".format(
                value, bundle['name']))


def layer_name(config):
    if config['layer'] == "base":
        return "base"
    else:
        return "{}/{}".format(config['layer'], config['name'])


@click.group(cls=DYMGroup)
def config():
    """
    Manage dynamic configuration layers.
    """
    pass  # pragma: nocover


@config.command()
@click.argument("bundle", callback=bundle_validators.validate_bundle_name,
                required=True, metavar="BUNDLE_NAME")
@cogctl.error_handler
@click.pass_obj
def layers(state, bundle):
    """List the configuration layers of a bundle.
    """

    layer_names = sorted([layer_name(c)
                          for c in state.api.dynamic_configs(bundle)])

    if layer_names:
        for l in layer_names:
            click.echo(l)
    else:
        output.info("No dynamic configuration layers for {}".format(
            bundle['name']))


@config.command()
@click.argument("bundle", callback=bundle_validators.validate_bundle_name,
                required=True, metavar="BUNDLE_NAME")
@click.argument("layer", required=False, callback=check_layer,
                default="base")
@cogctl.error_handler
@click.pass_obj
def info(state, bundle, layer):
    """Show the contents of a configuration layer.

    NOTE: This does not take into account any layering of multiple
    layers. It only shows the contents of the single specified layer.

    Output is returned as valid YAML.

    """
    click.echo(yaml.dump(layer['config'],
                         default_flow_style=False,
                         default_style='"').strip())


@config.command()
@click.argument("bundle", callback=bundle_validators.validate_bundle_name,
                required=True, metavar="BUNDLE_NAME")
@click.argument("config_file", type=click.Path(exists=True, file_okay=True,
                                               dir_okay=False, readable=True,
                                               allow_dash=True))
@click.option("--layer", "-l", required=False, callback=check_layer_name,
              default="base", show_default=True,
              help="configuration layer to operate on")
@cogctl.error_handler
@click.pass_obj
def create(state, bundle, config_file, layer):
    """Create a new dynamic configuration layer for a bundle.

    Layers are combined to create the final dynamic configuration that
    is in place when a command is executed. The layer names are as
    follows:

    - "base": in the absence of anything else, this configuration will
      be in effect.
    - "room/$ROOM": commands executed in the chat room `$ROOM` will
      layer this configuration on top of `base`
    - "user/$USER": commands executed by the user `$USER` will layer
      this configuration on last

    If no `--layer` option is given, a `base` layer is created.

    The configuration file given must be a YAML map.

    For more details, see
    https://cog-book.operable.io/sections/dynamic_command_configuration.html.
    """

    try:
        with click.open_file(config_file) as f:
            content = yaml.load(f.read())
    except yaml.parser.ParserError:
        raise click.BadParameter("Invalid YAML", param_hint=["config_file"])

    layer, name = layer
    r = state.api.create_config_layer(bundle, layer, name, content)
    output.info("Created {} layer for '{}' bundle".format(
        layer_name(r), r['bundle_name']))


@config.command()
@click.argument("bundle", callback=bundle_validators.validate_bundle_name,
                required=True, metavar="BUNDLE_NAME")
@click.argument("layer", required=False, callback=check_layer,
                default="base")
@cogctl.error_handler
@click.pass_obj
def delete(state, bundle, layer):
    """
    Delete a dynamic configuration layer.
    """

    state.api.delete_dynamic_config(bundle, layer['layer'], layer['name'])

    output.info("Deleted '{}' layer for bundle '{}'".format(
        layer_name(layer), bundle['name']))

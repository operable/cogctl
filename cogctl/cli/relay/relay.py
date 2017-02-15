import click
import cogctl
import cogctl.api
from cogctl.cli import table
from cogctl.cli.util import raise_if_not_all_present, compact_dict


def validate_new_relay_name(context, param, value):
    """
    Validates uniqueness of new relay name.
    """
    relays = context.obj.api.relays()
    exists = any(r for r in relays
                 if r["name"] == value)
    if exists:
        error = "Relay \"%s\" already exists" % value
        raise click.BadParameter(error)

    return value


def validate_new_relay_id(context, param, value):
    """
    Validates uniqueness and format of new relay id.
    """
    relay_id = str(value).lower()
    relays = context.obj.api.relays()
    exists = any(r for r in relays if r["id"] == relay_id)
    if exists:
        error = "Relay with ID \"%s\" already exists" % relay_id
        raise click.BadParameter(error)

    return relay_id


def validate_relay_groups(context, param, value):
    """
    Validates presence of relay groups by name.
    """
    if value == ():
        return value

    names = [name for names in value for name in names.split(",")]
    groups = context.obj.api.relay_groups(*names)
    raise_if_not_all_present(names, groups,
                             "Relay Groups {} do not exist")
    return groups


def validate_relay(context, param, value):
    """
    Validates presence of relay by name.
    """
    relays = context.obj.api.relays()
    relay = next((r for r in relays
                  if r["name"] == value), None)
    if relay is None:
        error = "Relay \"%s\" does not exist" % value
        raise click.BadParameter(error)

    return relay


@click.group(invoke_without_command=True)
@click.pass_context
@cogctl.error_handler
def relay(context):
    """
    Manage relays.

    Lists relays when called without a subcommand.
    """
    if context.invoked_subcommand is None:
        relays = context.obj.api.relays()
        for relay in relays:
            relay["status"] = "enabled" if relay["enabled"] else "disabled"
        output = table.render_dicts(relays, ["name", "status", "id"])
        click.echo(output)


@relay.command()
@click.argument("name", callback=validate_new_relay_name)
@click.argument("relay_id", type=click.UUID, callback=validate_new_relay_id)
@click.argument("token")
@click.option("--description", "-d", help="Description of the relay")
@click.option("--enable", "-e", is_flag=True, default=False,
              help="Enable a relay during creation",
              show_default=True)
@click.option("--relay-group", "-r", multiple=True,
              help="Relay groups to add the created relay to",
              callback=validate_relay_groups)
@click.pass_obj
@cogctl.error_handler
def create(obj, name, relay_id, token, description, enable, relay_group):
    "Create a relay"
    relay = obj.api.new_relay(name, relay_id, token, description=description,
                              enabled=enable, relay_groups=relay_group)
    output = render_relay(relay)
    click.echo(output)


@relay.command()
@click.argument("relay", callback=validate_relay)
@click.pass_obj
@cogctl.error_handler
def enable(obj, relay):
    "Enable a relay"
    obj.api.set_relay_status(relay["id"], "enabled")


@relay.command()
@click.argument("relay", callback=validate_relay)
@click.pass_obj
@cogctl.error_handler
def disable(obj, relay):
    "Disable a relay"
    obj.api.set_relay_status(relay["id"], "disabled")


@relay.command()
@click.argument("relay", callback=validate_relay)
@click.pass_obj
@cogctl.error_handler
def info(obj, relay):
    "Show relay details"
    relay = obj.api.relay(relay["id"])
    output = render_relay(relay)
    click.echo(output)


@relay.command()
@click.argument("relay", callback=validate_relay)
@click.option("--token", "-t")
@click.option("--description", "-d", help="Description of the relay")
@click.pass_obj
@cogctl.error_handler
def update(obj, relay, token, description):
    "Update a relay"
    data = {"token": token,
            "description": description}
    relay = obj.api.update_relay(relay["id"], compact_dict(data))
    output = render_relay(relay)
    click.echo(output)


@relay.command()
@click.argument("relay", callback=validate_relay)
@click.argument("new_name", callback=validate_new_relay_name)
@click.pass_obj
@cogctl.error_handler
def rename(obj, relay, new_name):
    "Rename a relay"
    obj.api.update_relay(relay["id"], {"name": new_name})


@relay.command()
@click.argument("relay", callback=validate_relay)
@click.pass_obj
@cogctl.error_handler
def delete(obj, relay):
    "Delete a relay"
    obj.api.delete_relay(relay["id"])


def render_relay(relay):
    relay["description"] = relay["description"] or ""
    relay["status"] = "enabled" if relay["enabled"] else "disabled"
    relay["groups"] = ", ".join(rg["name"] for rg in relay["groups"])
    headers = ["name", "id", "status", "description", "groups"]
    return table.render_dict(relay, headers)

import click
from click_didyoumean import DYMGroup
import cogctl
import cogctl.cli.output as output
import cogctl.cli.table as table
from operator import itemgetter
from cogctl.cli.util import raise_if_not_all_present


# Validation Callbacks
########################################################################

def check_name_available(ctx, param, value):
    "Verify that no relay group exists with the given name."
    if ctx.obj.api.relay_groups(value):
        raise click.BadParameter(
            "A relay group named '{}' already exists.".format(value))

    return value


def check_relays(ctx, param, value):
    """Ensure that all given names refer to existing relays.

    Assumes that this can be an optional value.

    """
    if value:
        relays = ctx.obj.api.relays(*value)
        raise_if_not_all_present(value,
                                 relays,
                                 "The following relays do not exist: {}")
        return relays


def check_groups_exist(ctx, param, value):
    "Ensure that all given names refer to existing relay groups."

    groups = ctx.obj.api.relay_groups(*value)
    raise_if_not_all_present(value, groups,
                             "The following relay groups do not exist: {}")
    return groups


def check_relays_in_group(ctx, param, value):
    """Ensure that all the given names refer to relays that are already in
    the relay group given in the argument "group" (which must have
    been validated before this runs).

    """
    if value:
        group = ctx.params["group"]
        relays = [r for r in group["relays"]
                  if r["name"] in value]

        raise_if_not_all_present(value, relays,
                                 "The following relays are not members "
                                 "of the group '" + group["name"] + "': {}")
        return relays


def check_bundles(ctx, param, value):
    """Use this to convert a number of bundle names into bundle objects.

    Raises an exception if all names do not refer to existing bundles.

    """
    bundles = ctx.obj.api.bundles(*value)
    raise_if_not_all_present(value,
                             bundles,
                             "The following bundles do not exist: {}")
    return bundles


def check_group(ctx, param, value):
    "Verify that a single relay group exists and return it."
    group = ctx.obj.api.relay_groups(value)

    if len(group) == 1:
        return group[0]
    else:
        raise click.BadParameter(
            "The relay group '{}' does not exist".format(value))


def check_bundles_in_group(ctx, param, value):
    """Ensure that all the given names refer to bundles that are already
    assigned to the relay group given in the argument "group" (which
    must have been validated before this runs).

    """
    if value:
        group = ctx.params["group"]
        bundles = [b for b in group["bundles"]
                   if b["name"] in value]
        raise_if_not_all_present(value, bundles,
                                 "The following bundles are not "
                                 "assigned to the group '" +
                                 group["name"] + "': {}")
        return bundles


# Helper Functions
########################################################################


def show_current_relay_members(response):
    """Given an API response object, generate a message showing the
    current relay members of a group. Use after modifying the
    membership.

    """
    if response["relays"]:
        msg = "Relay group '{}' has the following relay members: {}".format(
            response["name"],
            ", ".join(sorted([r["name"] for r in response["relays"]])))
    else:
        msg = "Relay group '{}' has no relay members.".format(response["name"])

    output.info(msg)


def show_current_assigned_bundles(response):
    """Given an API response object, generate a message showing the
    currently assigned bundles of a group. Use after modifying the
    membership.

    """
    if response["bundles"]:
        msg = "Relay group '{}' has the following assigned bundles: {}".format(
            response["name"],
            ", ".join(sorted([b["name"] for b in response["bundles"]])))
    else:
        msg = "Relay group '{}' has no assigned bundles.".format(
            response["name"])

    output.info(msg)


def add_relays_to_group(api, group, relays):
    """Helper function to add multiple relays to a group, either at group
    creation time, or later.

    """
    resp = api.add_relays_to_group(group, relays)
    show_current_relay_members(resp)


# Commands
########################################################################


@click.group(name="relay-group", invoke_without_command=True, cls=DYMGroup)
@cogctl.error_handler
@click.pass_context
def relay_group(ctx):
    """Manage relay groups.

    If invoked without a subcommand, lists all relay groups that
    exist.

    """
    if ctx.invoked_subcommand is None:
        groups = ctx.obj.api.relay_groups()
        click.echo(table.render_dicts(
            sorted(groups, key=itemgetter("name")),
            # TODO: Not sure how useful "inserted_at" is?
            ["name", "inserted_at", "id"]))


@relay_group.command()
@click.argument("name", callback=check_name_available)
@click.argument("relays", callback=check_relays, nargs=-1)
@cogctl.error_handler
@click.pass_obj
def create(state, name, relays):
    """Create a relay group.

    If any relay names are supplied, they will be added as members of
    the newly-created group.

    """

    group = state.api.create_relay_group(name)
    output.info("Created relay group '{}'".format(group["name"]))

    if relays:
        add_relays_to_group(state.api, group, relays)


@relay_group.command()
@click.argument("groups", required=True, callback=check_groups_exist, nargs=-1)
@cogctl.error_handler
@click.pass_obj
def delete(state, groups):
    """Delete relay groups.

    Groups must have neither bundles assigned to it, nor relays
    associated with it.

    """

    for g in groups:
        state.api.delete_relay_group(g)
        output.info("Deleted relay group '{}'".format(g["name"]))


@relay_group.command()
@click.argument("group", callback=check_group)
@click.argument("relays", required=True, callback=check_relays, nargs=-1)
@click.pass_obj
def add(state, group, relays):
    """
    Add relays to a relay group.
    """
    add_relays_to_group(state.api, group, relays)


@relay_group.command()
@click.argument("group", callback=check_group)
@click.argument("relays", callback=check_relays_in_group, nargs=-1)
@click.option("--all", "-a", required=False, is_flag=True, default=False,
              help="Remove all relays from the group",
              show_default=True)
@click.pass_obj
def remove(state, group, relays, all):
    """Remove relays from a relay group.

    You can provide one or more names of relays currently in the group
    that you would like to remove, or remove all relays from the group
    with the `--all` option.

    """
    if not (relays or all):
        raise click.BadParameter(
            "You must provide either relay names, "
            "or specify the '--all' option")

    if relays and all:
        raise click.BadParameter(
            "You cannot provide both relay names and the '--all' option")

    if all:
        relays = group["relays"]
        output.warn("Removing ALL relays from group '{}': {}".format(
            group["name"],
            ", ".join(sorted([r["name"] for r in relays]))))

    resp = state.api.remove_relays_from_group(group, relays)
    show_current_relay_members(resp)


@relay_group.command()
@click.argument("group", callback=check_group)
@click.argument("bundles", required=True, callback=check_bundles, nargs=-1)
@click.pass_obj
def assign(state, group, bundles):
    """Assign bundles to a relay group.

    Commands in those bundles will be executed on relays within this
    relay group.

    """
    resp = state.api.assign_bundles_to_group(group, bundles)
    show_current_assigned_bundles(resp)


@relay_group.command()
@click.argument("group", callback=check_group)
@click.argument("bundles", callback=check_bundles_in_group, nargs=-1)
@click.option("--all", "-a", required=False, is_flag=True, default=False,
              help="Unassign all bundles from the group",
              show_default=True)
@click.pass_obj
def unassign(state, group, bundles, all):
    """Unassign bundles from a relay group.

    Commands in those bundles will no longer be executed on the relays
    of the group.

    You can provide one or more names of bundles currently assigned to
    the group that you would like to unassign, or unassign all bundles
    from the group with the `--all` option.

    """

    if not (bundles or all):
        raise click.BadParameter(
            "You must provide either bundle names, "
            "or specify the '--all' option")

    if bundles and all:
        raise click.BadParameter(
            "You cannot provide both bundle names and the '--all' option")

    if all:
        bundles = group["bundles"]
        output.warn("Unassigning ALL bundles from group '{}': {}".format(
            group["name"],
            ", ".join(sorted([b["name"] for b in bundles]))))

    resp = state.api.unassign_bundles_from_group(group, bundles)
    show_current_assigned_bundles(resp)


@relay_group.command()
@click.argument("group", callback=check_group)
def info(group):
    "Show details of a single relay group."

    group_info = [["Name", group["name"]],
                  ["ID", group["id"]],
                  ["Creation Time", group["inserted_at"]]]

    click.echo(table.render(group_info))

    click.echo()
    click.echo("Relays")
    click.echo(table.render_dicts(
        sorted(group["relays"], key=itemgetter("name")),
        ["name", "id"]))

    click.echo()
    click.echo("Bundles")
    click.echo(table.render_dicts(
        sorted(group["bundles"], key=itemgetter("name")),
        ["name", "id"]))

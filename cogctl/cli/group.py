import click
from click_didyoumean import DYMGroup
import cogctl
import cogctl.cli.table as tbl
import cogctl.cli.output as output


def validate_group(ctx, param, value):
    """
    Validates the existance of the group.
    Gets the group by name, returning it if it exists and
    throwing a BadParameter error if it does not.
    """
    group = ctx.obj.api.group_by_name(value)
    output.debug("Checking that the group name is valid")
    if group:
        return group
    else:
        raise click.BadParameter("\"%s\" was not found" % value)


def validate_new_group_name(ctx, param, value):
    """
    Validates the uniqueness of the new group name.
    Group names must be unique. This verifies that the group
    name has not already been taken.
    """
    groups = ctx.obj.api.groups()
    # If a group with the specified name already exists then we throw
    # a BadParameter error.
    output.debug("Checking that the group name is not in use")
    if any(group for group in groups if group['name'] == value):
        raise click.BadParameter("Group with name \"%s\" already exists"
                                 % value)
    else:
        return value


def validate_user_names(ctx, param, value):
    """
    Validates the existence of one or more usernames.
    Duplicate usernames are discarded.
    """
    output.debug("Checking that the specified users exist")
    users = ctx.obj.api.users()
    to_add = set(value)
    diff = to_add.difference({user['username'] for user in users})
    if diff:
        err = "The following user/s could not be found: %s" % ", ".join(diff)
        raise click.BadParameter(err)
    else:
        return list(to_add)


def validate_roles(ctx, param, value):
    """
    Validates the existence of one or more roles.
    Duplicate names are discarded.
    """
    output.debug("Checking that the specified roles exist")
    roles = ctx.obj.api.roles()
    to_add = set(value)
    diff = to_add.difference({role['name'] for role in roles})
    if diff:
        err = "The following role/s could not be found: %s" % ", ".join(diff)
        raise click.BadParameter(err)
    else:
        return list(to_add)


@click.group(invoke_without_command=True, cls=DYMGroup)
@click.pass_context
@cogctl.error_handler
def group(ctx):
    """Manage Cog user groups.

    If invoked without a subcommand, lists all user groups.
    """
    if ctx.invoked_subcommand is None:
        groups = ctx.obj.api.groups()
        table = tbl.render_dicts(groups, ["name", "id"])
        output.echo(table)


@group.command()
@click.argument("name", callback=validate_new_group_name)
@click.pass_obj
@cogctl.error_handler
def create(obj, name):
    """
    Create a new user group.
    """
    group = obj.api.new_group(name)
    output.info(group_table(group))


@group.command()
@click.argument("group", callback=validate_group)
@cogctl.error_handler
def info(group):
    """
    Show info on a specific group.
    """
    output.echo(group_table(group))


@group.command()
@click.argument("group", callback=validate_group)
@click.argument("new_name", callback=validate_new_group_name)
@click.pass_obj
@cogctl.error_handler
def rename(obj, group, new_name):
    """
    Rename a user group.
    """
    group = obj.api.update_group(group['id'], {'name': new_name})
    output.info(group_table(group))


@group.command()
@click.argument("group", callback=validate_group)
@click.pass_obj
@cogctl.error_handler
def delete(obj, group):
    """
    Delete a group.
    """
    obj.api.delete_group(group['id'])
    output.info(group_table(group))


@group.command()
@click.argument("group", callback=validate_group)
@click.argument("usernames",
                nargs=-1,
                required=True,
                callback=validate_user_names)
@click.pass_obj
@cogctl.error_handler
def add(obj, group, usernames):
    """
    Add one or more users to a group.
    """
    group = obj.api.add_group_users(group['id'], usernames)
    output.info(group_table(group))


@group.command()
@click.argument("group", callback=validate_group)
@click.argument("usernames",
                nargs=-1,
                required=True,
                callback=validate_user_names)
@click.confirmation_option(prompt="Are you sure?", is_eager=True)
@click.pass_obj
@cogctl.error_handler
def remove(obj, group, usernames):
    """
    Remove one or more users from a group.
    """
    group = obj.api.remove_group_users(group['id'], usernames)
    output.info(group_table(group))


@group.command()
@click.argument("group", callback=validate_group)
@click.argument("roles", nargs=-1, required=True, callback=validate_roles)
@click.pass_obj
@cogctl.error_handler
def grant(obj, group, roles):
    """
    Grant one or more roles to a group.
    """
    group = obj.api.grant_group_roles(group['id'], roles)
    output.info(group_table(group))


@group.command()
@click.argument("group", callback=validate_group)
@click.argument("roles", nargs=-1, required=True, callback=validate_roles)
@click.confirmation_option(prompt="Are you sure?", is_eager=True)
@click.pass_obj
@cogctl.error_handler
def revoke(obj, group, roles):
    """
    Revoke one or more roles from a group.
    """
    group = obj.api.revoke_group_roles(group['id'], roles)
    output.info(group_table(group))


def group_table(group):
    data = [["ID", group["id"]],
            ["Name", group["name"]],
            ["Users", ", ".join(user['username']
                                for user in group['members']['users'])],
            ["Roles", ", ".join(role['name']
                                for role in group['members']['roles'])]]
    return tbl.render(data)

import click
from click_didyoumean import DYMGroup
import cogctl
import cogctl.api
from cogctl.cli import table
from cogctl.cli.permission import parse_permission_name


def validate_role(context, param, value):
    """
    Validates existance of role. Fetches the role by name, returning it
    if it exists; otherwise throws BadParameter
    """
    role = context.obj.api.role_by_name(value)
    if role:
        return role
    else:
        raise click.BadParameter("\"%s\" was not found" % value)


def validate_new_role_name(context, param, value):
    "Validates uniqueness of new role name"
    roles = context.obj.api.roles()
    if any(r for r in roles if r["name"] == value):
        error = "Role with name \"%s\" already exists" % value
        raise click.BadParameter(error)
    else:
        return value


def validate_permission(context, param, value):
    """
    Validates existance of permission. Fetches the permission by full
    name, returning it if it exists; otherwise throws BadParameter
    """
    [bundle, name] = parse_permission_name(value)
    permission = context.obj.api.permission_by_name(bundle, name)
    if permission:
        return permission
    else:
        raise click.BadParameter("\"%s\" was not found" % value)


@click.group(invoke_without_command=True, cls=DYMGroup)
@click.pass_context
@cogctl.error_handler
def role(context):
    """
    Manage roles and role grants.

    Lists roles when called without a subcommand.
    """
    if context.invoked_subcommand is None:
        roles = context.obj.api.roles()
        output = table.render_dicts(roles, ["name", "id"])
        click.echo(output)


@role.command()
@click.argument("name", callback=validate_new_role_name)
@click.pass_obj
@cogctl.error_handler
def create(obj, name):
    "Create a role"
    role = obj.api.new_role(name)
    output = render_role(role)
    click.echo(output)


@role.command()
@click.argument("role", callback=validate_role)
@cogctl.error_handler
def info(role):
    "Show role details"
    output = render_role(role)
    click.echo(output)


@role.command()
@click.argument("role", callback=validate_role)
@click.argument("new_name", callback=validate_new_role_name)
@click.pass_obj
@cogctl.error_handler
def rename(obj, role, new_name):
    "Rename a role"
    role = obj.api.update_role(role["id"], {"name": new_name})
    output = render_role(role)
    click.echo(output)


@role.command()
@click.argument("role", callback=validate_role)
@click.pass_obj
@cogctl.error_handler
def delete(obj, role):
    "Delete a role"
    obj.api.delete_role(role["id"])


@role.command()
@click.argument("role", callback=validate_role)
@click.argument("permission", callback=validate_permission)
@click.pass_obj
@cogctl.error_handler
def grant(obj, role, permission):
    "Grant a permission to a role"
    permission_name = permission["bundle"] + ":" + permission["name"]
    obj.api.new_role_grant(role["id"], permission_name)


@role.command()
@click.argument("role", callback=validate_role)
@click.argument("permission", callback=validate_permission)
@click.pass_obj
@cogctl.error_handler
def revoke(obj, role, permission):
    "Revoke a permission from a role"
    permission_name = permission["bundle"] + ":" + permission["name"]
    obj.api.delete_role_grant(role["id"], permission_name)


def render_role(role):
    role["permissions"] = ", ".join([p["name"] for p in role["permissions"]])
    role["groups"] = ", ".join([g["name"] for g in role["groups"]])
    return table.render_dict(role, ["name", "id", "permissions", "groups"])

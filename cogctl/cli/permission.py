import click
from click_didyoumean import DYMGroup
import cogctl
import cogctl.api
from cogctl.cli import table


def validate_new_permission_name(context, param, value):
    """
    Validates uniqueness of new permission name and requires the bundle to be
    "site" if included in the full name of the permission.
    """
    [bundle, permission] = parse_permission_name(value, require_site=True)
    permissions = context.obj.api.permissions()
    exists = any(p for p in permissions
                 if p["bundle"] == "site" and
                 p["name"] == permission)

    if exists:
        error = "Permission \"site:%s\" already exists" % permission
        raise click.BadParameter(error)
    else:
        return permission


def validate_permission(context, param, value):
    """
    Validates existance of permission. Fetches the permission by full
    name, returning it if it exists; otherwise throws BadParameter
    """
    [bundle, permission] = parse_permission_name(value)
    permission = context.obj.api.permission_by_name(bundle, permission)
    if permission:
        return permission
    else:
        raise click.BadParameter("Permission \"%s\" not found" % value)


def parse_permission_name(name, require_site=False):
    segments = name.split(":")

    if len(segments) == 2 and (require_site and segments[0] != "site"):
        error = "Permissions must be created in the \"site\" bundle (e.g. site:deploy)" # noqa
        raise click.BadParameter(error)
    elif len(segments) > 2:
        raise click.BadParameter("Invalid permission name \"%s\"" % name)

    if len(segments) == 1:
        return ["site", segments[0]]
    else:
        return segments


@click.group(invoke_without_command=True, cls=DYMGroup)
@click.pass_context
@cogctl.error_handler
def permission(context):
    """
    Manage permissions.

    Lists permissions when called without a subcommand.
    """
    if context.invoked_subcommand is None:
        permissions = context.obj.api.permissions()
        for p in permissions:
            p["name"] = p["bundle"] + ":" + p["name"]
        output = table.render_dicts(permissions, ["name", "id"])
        click.echo(output)


@permission.command()
@click.argument("name", callback=validate_new_permission_name)
@click.pass_obj
@cogctl.error_handler
def create(obj, name):
    "Create a site permission"
    permission = obj.api.new_permission(name)
    output = render_permission(permission)
    click.echo(output)


@permission.command()
@click.argument("permission", callback=validate_permission)
@click.pass_obj
@cogctl.error_handler
def info(obj, permission):
    "Show permission details"
    output = render_permission(permission)
    click.echo(output)


@permission.command()
@click.argument("permission", callback=validate_permission)
@click.pass_obj
@cogctl.error_handler
def delete(obj, permission):
    "Delete a permission"
    obj.api.delete_permission(permission["id"])


def render_permission(permission):
    permission["name"] = permission["bundle"] + ":" + permission["name"]
    return table.render_dict(permission, ["name", "id"])

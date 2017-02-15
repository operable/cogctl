import click
from click_didyoumean import DYMGroup
import cogctl
import cogctl.api
from cogctl.cli import table
from requests.exceptions import HTTPError

SUMMARY_FIELDS = ["name", "pipeline", "enabled"]
DETAIL_FIELDS = ["name", "pipeline", "enabled", "as_user", "timeout_sec",
                 "invocation_url"]


def user_exists(context, param, value):
    if value is not None:
        try:
            context.obj.api.user_by_name(value)
            return value
        except HTTPError as e:
            if e.response.status_code == 404:
                raise click.BadOptionUsage('User "%s" was not found' % value)
            else:
                raise click.BadOptionUsage(e.strerror)


def validate_new_trigger_name(context, param, value):
    if context.command_path in ["update", "cogctl trigger update"]:
        if value is None:
            return value
    triggers = context.obj.api.trigger_by_name(value)
    if len(triggers) > 0:
        raise click.BadParameter('Trigger "%s" already exists' % value)
    else:
        return value


def validate_timeout(context, param, value):
    if value is None:
        return value
    try:
        return int(value)
    except ValueError:
        raise click.BadParameter("\"%s\" is not a valid integer" % value)


@click.group(invoke_without_command=True, cls=DYMGroup)
@click.pass_context
@cogctl.error_handler
def trigger(context):
    """
    Create, edit, delete, and view Cog triggers.

    If invoked without a subcommand, lists all triggers.
    """
    if context.invoked_subcommand is None:
        triggers = context.obj.api.triggers()
        output = table.render_dicts(triggers, SUMMARY_FIELDS)
        click.echo(output)


@trigger.command()
@click.option("--enable", is_flag=True, help="Enable newly created trigger")
@click.option("--as-user",
              help="Trigger will execute with this user's permissions",
              callback=user_exists)
@click.option("--timeout", default="60",
              help="Maximum time trigger is allowed to run",
              callback=validate_timeout)
@click.option("--description", help="Trigger description")
@click.argument("name", callback=validate_new_trigger_name)
@click.argument("pipeline")
@click.pass_obj
@cogctl.error_handler
def create(obj, name, pipeline, **kwargs):
    "Create a new trigger"
    try:
        trigger = obj.api.create_trigger(name, pipeline, **kwargs)
        click.echo(table.render_dict(trigger, SUMMARY_FIELDS))
    except HTTPError as e:
        raise click.ClickException(e.response.text)


@trigger.command()
@click.argument("name")
@click.pass_obj
@cogctl.error_handler
def info(obj, name):
    "Display trigger details"
    item = None
    items = obj.api.trigger_by_name(name)
    if len(items) == 0:
        raise click.ClickException('Trigger "%s" not found' % name)
    else:
        item = items[0]
        click.echo(table.render_dict(item, DETAIL_FIELDS))


@trigger.command()
@click.option("--force", is_flag=True,
              help="Force trigger deletion")
@click.argument("name")
@click.pass_obj
@cogctl.error_handler
def delete(obj, name, force=False):
    "Delete a trigger"
    if force is False:
        click.confirm("Are you sure?", abort=True)
    items = obj.api.trigger_by_name(name)
    if len(items) == 0:
        raise click.ClickException('Trigger "%s" not found' % name)
    else:
        obj.api.delete_trigger(items[0]["id"])
        click.echo('Trigger "%s" deleted' % name)


@trigger.command()
@click.option("--name", callback=validate_new_trigger_name,
              help="New name for trigger")
@click.option("--enable", is_flag=True, help="Enable trigger")
@click.option("--disable", is_flag=True, help="Disable trigger")
@click.option("--as-user", callback=user_exists,
              help="Trigger will execute with this user's permissions",)
@click.option("--timeout", callback=validate_timeout,
              help="Maximum time trigger is allowed to run")
@click.option("--pipeline",
              help="Command pipeline attached to trigger")
@click.option("--description", help="Trigger description")
@click.argument("trigger_name")
@click.pass_obj
@cogctl.error_handler
def update(obj, trigger_name, **kwargs):
    "Update trigger configuration"
    if kwargs["enable"] and kwargs["disable"]:
        raise click.BadOptionUsage("Trigger cannot be both " +
                                   "enabled and disabled")
    items = obj.api.trigger_by_name(trigger_name)
    if len(items) == 0:
        raise click.ClickException('Trigger "%s" not found' % trigger_name)
    else:
        trigger = items[0]
        data = {}
        for key in kwargs.keys():
            if kwargs[key] is not None:
                if key == "enable" and kwargs[key]:
                    data["enabled"] = True
                elif key == "disable" and kwargs[key]:
                    data["enabled"] = False
                elif key == "timeout":
                    data["timeout_sec"] = kwargs[key]
                else:
                    data[key] = kwargs[key]
        result = obj.api.update_trigger(trigger["id"], data)
        click.echo(table.render_dict(result, DETAIL_FIELDS))

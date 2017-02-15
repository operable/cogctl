import click
from click_didyoumean import DYMGroup
import cogctl
import cogctl.api
from cogctl.cli import table


def validate_command(context, param, value):
    """
    Validates the existance of a command.  Gets the command by name,
    returning it if it exists and throwing a BadParameter error if it does
    not.
    """
    segments = value.split(":")
    if len(segments) != 2:
        raise click.BadParameter("Command \"%s\" was not found" % value)

    [bundle, command] = segments
    command = context.obj.api.command_by_name(bundle, command)
    if not command:
        raise click.BadParameter("Command \"%s\" was not found" % value)

    return command


def validate_rule(context, param, value):
    """
    Validates existance of rule. Fetches the rule by id, returning it
    if it exists; otherwise throws BadParameter
    """
    rule = context.obj.api.rule(value)
    if not rule:
        raise click.BadParameter("\"%s\" was not found" % value)

    return rule


@click.group(invoke_without_command=True, cls=DYMGroup)
@click.pass_context
@cogctl.error_handler
def rule(context):
    """
    Manage rules.
    """
    if context.invoked_subcommand is None:
        raise click.BadParameter("Subcommand required")


@rule.command(name="list")
@click.argument("command", nargs=1, required=True,
                callback=validate_command)
@click.pass_obj
@cogctl.error_handler
def list_rules(obj, command):
    rules = obj.api.rules_for_command(command)
    output = table.render_dicts(rules, ["id", "rule"])
    click.echo(output)


@rule.command()
@click.argument("rule", nargs=-1, required=True)
@click.pass_obj
@cogctl.error_handler
def create(obj, rule):
    """
    Create rule.

    For complex rules you may need to surround the entire rule in quotes to
    ensure it's created correctly.
    """
    rule = obj.api.new_rule(" ".join(rule))
    output = table.render_dict(rule, ["id", "rule"])
    click.echo(output)


@rule.command()
@click.argument("rule", required=True, callback=validate_rule)
@click.pass_obj
@cogctl.error_handler
def delete(obj, rule):
    """
    Delete rule.
    """
    obj.api.delete_rule(rule["id"])

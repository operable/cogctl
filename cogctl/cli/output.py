import click


def echo(msg):
    """
    Message ALWAYS prints exactly as it was passed.
    prints to stdout
    """
    click.echo(msg)


def error(msg):
    """
    Message ALWAYS prints with the string "Error: " prepended.
    prints to stderr
    """
    click.echo("Error: %s" % msg, err=True)


def warn(msg):
    """
    Message ALWAYS prints with the string "Warning: " prepended.
    prints to stderr
    """
    click.echo("Warning: %s" % msg, err=True)


@click.pass_obj
def info(obj, msg):
    """
    Message prints IF the verbosity is set to 1 or higher
    prints to stdout
    """
    if obj.verbosity >= 1:
        click.echo(msg)


@click.pass_obj
def debug(obj, msg):
    """
    Message prints IF the verbosity is set to 2 or higher
    prints to stdout
    """
    if obj.verbosity >= 2:
        click.echo(msg)

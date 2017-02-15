import click
from click.testing import CliRunner
import cogctl.cli.output as output
from cogctl.cli.state import State


@click.command()
def cli():
    output.echo("echo should always print")
    output.error("error should always print")
    output.warn("warning should always print")
    output.info("info should print when verbosity is 1")
    output.debug("debug should print when verbosity is 2")


def test_default_verbosity():
    runner = CliRunner()
    state = State()
    state.verbosity = 0

    result = runner.invoke(cli, obj=state)

    assert result.output == """\
echo should always print
Error: error should always print
Warning: warning should always print
"""


def test_verbosity_one():
    runner = CliRunner()
    state = State()
    state.verbosity = 1

    result = runner.invoke(cli, obj=state)

    assert result.output == """\
echo should always print
Error: error should always print
Warning: warning should always print
info should print when verbosity is 1
"""


def test_verbosity_two():
    runner = CliRunner()
    state = State()
    state.verbosity = 2

    result = runner.invoke(cli, obj=state)

    assert result.output == """\
echo should always print
Error: error should always print
Warning: warning should always print
info should print when verbosity is 1
debug should print when verbosity is 2
"""

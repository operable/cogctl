import pytest
from functools import partial
from click.testing import CliRunner
from cogctl.cli.state import State


@pytest.fixture
def cogctl(cli_state):
    runner = CliRunner()

    with runner.isolated_filesystem():

        yield partial(runner.invoke,
                      catch_exceptions=False,
                      obj=cli_state)


@pytest.fixture
def cli_state():
    state = State()
    # Set the verbosity to 1 so we get some output
    state.verbosity = 1
    state.profile = {"url": "http://foo.bar.com:8080",
                     "user": "me",
                     "password": "seeeekrit"}
    return state

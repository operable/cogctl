from click.testing import CliRunner
import cogctl.cli.token
from cogctl.cli.state import State
import responses
import pytest


@pytest.fixture
def cli_state():
    state = State()
    state.profile = {"url": "http://foo.bar.com:8080",
                     "user": "me",
                     "password": "seeeekrit"}
    return state


def test_get_token_with_valid_credentials(cli_state):
    runner = CliRunner()
    with responses.RequestsMock() as rsps:
        rsps.add(responses.POST,
                 cli_state.profile["url"] + "/v1/token",
                 json={"token": {"value": "abcdef0123456789abcdef0123456789"}},
                 status=201)

        result = runner.invoke(cogctl.cli.token.token, obj=cli_state)

    assert result.exit_code == 0
    assert result.output == "abcdef0123456789abcdef0123456789\n"


def test_get_token_with_invalid_credentials(cli_state):
    runner = CliRunner()
    with responses.RequestsMock() as rsps:
        rsps.add(responses.POST,
                 cli_state.profile["url"] + "/v1/token",
                 json={"errors": "invalid credentials"},
                 status=403)
        result = runner.invoke(cogctl.cli.token.token,
                               obj=cli_state)

    assert result.exit_code == 1
    assert result.output == "Error: invalid credentials\n"

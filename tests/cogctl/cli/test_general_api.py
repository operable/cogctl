from cogctl.cli.token import token
from cogctl.cli.state import State


def test_behavior_with_invalid_connection_parameters(cogctl):
    # Note: we're not using any mocks, so the default address from our
    # testing configuration won't return anything.

    # We're using the token command arbitrarily; just want something
    # that tries to hit the API.
    result = cogctl(token)

    assert result.exit_code == 1
    assert result.output == """\
Error: Could not establish HTTP connection to http://foo.bar.com:8080/v1/token. Please check your host, user, and password settings.
"""  # noqa: E501


def test_behavior_with_missing_connection_parameters(cogctl):
    result = cogctl(token, obj=State())

    assert result.exit_code == 1
    assert result.output == """\
Error: Must set URL, user, and password to make API calls
"""

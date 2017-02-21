import pytest
import cogctl.cli.group as group
import responses


@pytest.fixture(autouse=True)
def mocks(request, cli_state):
    with responses.RequestsMock(assert_all_requests_are_fired=False) as rsps:
        # Simulates failed login
        rsps.add(responses.POST,
                 cli_state.profile["url"] + "/v1/token",
                 json={"errors": "Invalid credentials"},
                 status=403)
        yield rsps


def test_group_index(cogctl):
    result = cogctl(group.group)

    assert result.exit_code == 1
    assert result.output == "Error: Invalid credentials\n"

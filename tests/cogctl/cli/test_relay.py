import pytest
from cogctl.cli.relay import relay
import responses


@pytest.fixture(autouse=True)
def mocks(request, cli_state):
    with responses.RequestsMock(assert_all_requests_are_fired=False) as rsps:
        base_url = "%s/v1" % cli_state.profile["url"]
        relay_id = "a6f95083-78e2-4ace-b034-725d80d91717"

        # Token
        rsps.add(responses.POST,
                 "%s/token" % base_url,
                 json={"token": {"value": "lolwut"}},
                 status=200)

        # Relays Index
        rsps.add(responses.GET,
                 "%s/relays" % base_url,
                 json={"relays": [
                        {"id": "0e8ec7e2-7014-4991-9c5e-36115cb7bc67",
                         "name": "relay",
                         "enabled": True},
                        {"id": "a6f95083-78e2-4ace-b034-725d80d91717",
                         "name": "another-relay",
                         "enabled": False}]},
                 status=200)

        # Relays Create
        rsps.add(responses.POST,
                 "%s/relays" % base_url,
                 json={"relay": {"id": "639a4eb3-2b69-46c5-90f5-c53bc8930aae",
                                 "name": "prod-relay",
                                 "description": "Does a thing",
                                 "enabled": True,
                                 "groups": []}},
                 status=201)

        # Relays Show
        rsps.add(responses.GET,
                 "%s/relays/%s" % (base_url, relay_id),
                 json={"relay": {"id": "a6f95083-78e2-4ace-b034-725d80d91717",
                                 "name": "another-relay",
                                 "description": "Does a thing updated",
                                 "enabled": True,
                                 "groups": [{"name": "prod-group"},
                                            {"name": "dev-group"}]}},
                 status=200)

        rsps.add(responses.GET,
                 "%s/relays/%s" % (base_url, "639a4eb3-2b69-46c5-90f5-c53bc8930aae"), # noqa
                 json={"relay": {"id": "639a4eb3-2b69-46c5-90f5-c53bc8930aae",
                                 "name": "prod-relay",
                                 "description": "Does a thing",
                                 "enabled": True,
                                 "groups": [{"name": "prod-group"},
                                            {"name": "dev-group"}]}},
                 status=201)

        # Relays Update
        rsps.add(responses.PUT,
                 "%s/relays/%s" % (base_url, relay_id),
                 json={"relay": {"id": "a6f95083-78e2-4ace-b034-725d80d91717",
                                 "name": "another-relay",
                                 "description": "Does a thing updated",
                                 "enabled": True,
                                 "groups": [{"name": "prod-group"},
                                            {"name": "dev-group"}]}},
                 status=200)

        # Relays Delete
        rsps.add(responses.DELETE, "%s/relays/%s" % (base_url, relay_id),
                 status=204)

        # Relay Groups Index
        rsps.add(responses.GET, "%s/relay_groups" % base_url,
                 json={"relay_groups": [{
                           "id": "10fe4a9d-b5cc-4a42-a7d9-8bfba19573ae",
                           "name": "prod-group"}, {
                           "id": "96677a38-bb6e-4b18-bc50-dc7f32805293",
                           "name": "dev-group"}]},
                 status=200)

        # Relay Groups Member Add
        rsps.add(responses.POST,
                "%s/relay_groups/10fe4a9d-b5cc-4a42-a7d9-8bfba19573ae/relays" % base_url, # noqa
                json={"relay_group": {
                          "id": "10fe4a9d-b5cc-4a42-a7d9-8bfba19573ae",
                          "name": "prod-group",
                          "relays": [{
                              "id": "a6f95083-78e2-4ace-b034-725d80d91717"}]}},
                status=201)

        rsps.add(responses.POST,
                "%s/relay_groups/96677a38-bb6e-4b18-bc50-dc7f32805293/relays" % base_url, # noqa
                json={"relay_group": {
                          "id": "96677a38-bb6e-4b18-bc50-dc7f32805293",
                          "name": "dev-group",
                          "relays": [{
                              "id": "a6f95083-78e2-4ace-b034-725d80d91717"}]}},
                status=201)

        yield rsps


def test_relay_list(cogctl):
    result = cogctl(relay.relay)

    assert result.exit_code == 0
    assert result.output == """\
NAME           STATUS    ID
relay          enabled   0e8ec7e2-7014-4991-9c5e-36115cb7bc67
another-relay  disabled  a6f95083-78e2-4ace-b034-725d80d91717
"""


def test_relay_create(cogctl):
    result = cogctl(relay.create,
                    ["prod-relay", "639a4eb3-2b69-46c5-90f5-c53bc8930aae",
                     "sekret", "--description", "Does a thing", "--enable",
                     "--relay-group", "prod-group", "--relay-group",
                     "dev-group"])

    # assert result.exit_code == 0
    assert result.output == """\
Name         prod-relay
ID           639a4eb3-2b69-46c5-90f5-c53bc8930aae
Status       enabled
Description  Does a thing
Groups       prod-group, dev-group
"""


def test_relay_create_with_existing_relay_name(cogctl):
    result = cogctl(relay.create,
                    ["another-relay", "639a4eb3-2b69-46c5-90f5-c53bc8930aae",
                     "sekret"])

    assert not result.exit_code == 0

    bad_param = "Invalid value for \"name\""
    error = "Relay \"another-relay\" already exists"
    assert "Error: %s: %s" % (bad_param, error) in result.output


def test_relay_create_with_invalid_relay_id(cogctl):
    result = cogctl(relay.create,
                    ["prod-relay", "pony",
                     "sekret"])

    assert not result.exit_code == 0

    bad_param = "Invalid value for \"relay_id\""
    error = "pony is not a valid UUID value"
    assert "Error: %s: %s" % (bad_param, error) in result.output


def test_relay_create_with_existing_relay_id(cogctl):
    result = cogctl(relay.create,
                    ["prod-relay", "a6f95083-78e2-4ace-b034-725d80d91717",
                     "sekret"])

    assert not result.exit_code == 0

    bad_param = "Invalid value for \"relay_id\""
    error = "Relay with ID \"a6f95083-78e2-4ace-b034-725d80d91717\" already exists"
    assert "Error: %s: %s" % (bad_param, error) in result.output


def test_relay_enable(cogctl):
    result = cogctl(relay.enable, ["another-relay"])

    assert result.exit_code == 0
    assert result.output == ""


def test_relay_disable(cogctl):
    result = cogctl(relay.enable, ["another-relay"])

    assert result.exit_code == 0
    assert result.output == ""


def test_relay_info(cogctl):
    result = cogctl(relay.info, ["another-relay"])

    assert result.exit_code == 0
    assert result.output == """\
Name         another-relay
ID           a6f95083-78e2-4ace-b034-725d80d91717
Status       enabled
Description  Does a thing updated
Groups       prod-group, dev-group
"""


def test_relay_update(cogctl):
    result = cogctl(relay.update,
                    ["another-relay", "--token", "diff-sekret", "--description",
                     "Does a thing updated"])

    assert result.exit_code == 0
    assert result.output == """\
Name         another-relay
ID           a6f95083-78e2-4ace-b034-725d80d91717
Status       enabled
Description  Does a thing updated
Groups       prod-group, dev-group
"""


def test_relay_rename(cogctl):
    result = cogctl(relay.rename,
                    ["another-relay", "renamed-relay"])

    assert result.exit_code == 0
    assert result.output == ""


def test_relay_delete(cogctl):
    result = cogctl(relay.delete, ["another-relay"])

    assert result.exit_code == 0
    assert result.output == ""

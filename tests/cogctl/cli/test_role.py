import pytest
from cogctl.cli import role
import responses


@pytest.fixture(autouse=True)
def mocks(request, cli_state):
    with responses.RequestsMock(assert_all_requests_are_fired=False) as rsps:
        base_url = "%s/v1" % cli_state.profile["url"]
        role_id = "c7eab02d-cfcb-4a99-a42c-9cfe5deb24a2"

        # Token
        rsps.add(responses.POST,
                 "%s/token" % base_url,
                 json={"token": {"value": "lolwut"}},
                 status=200)

        # Roles Index
        rsps.add(responses.GET,
                 "%s/roles" % base_url,
                 json={"roles": [{"id": "c7eab02d-cfcb-4a99-a42c-9cfe5deb24a2",
                                  "name": "monkey",
                                  "permissions": [{"name": "manage_roles"}],
                                  "groups": [{"name": "robots"}]},
                                 {"id": "caf9f4d3-fb11-4cf9-96d1-eafa7cbc858b",
                                  "name": "second",
                                  "permissions": [],
                                  "groups": []}]},
                 status=200)

        # Roles Create
        rsps.add(responses.POST,
                 "%s/roles" % base_url,
                 json={"role": {"id": "c7eab02d-cfcb-4a99-a42c-9cfe5deb24a2",
                                "name": "new_monkey",
                                "permissions": [],
                                "groups": []}},
                 status=201)

        # Roles Update
        rsps.add(responses.PUT,
                 "%s/roles/%s" % (base_url, role_id),
                 json={"role": {"id": "c7eab02d-cfcb-4a99-a42c-9cfe5deb24a2",
                                "name": "cheeseburger",
                                "permissions": [{"name": "manage_roles"}],
                                "groups": [{"name": "robots"}]}},
                 status=200)

        # Roles Delete
        rsps.add(responses.DELETE,
                 "%s/roles/%s" % (base_url, role_id),
                 json={"role": {"id": "c7eab02d-cfcb-4a99-a42c-9cfe5deb24a2",
                                "name": "cheeseburger",
                                "permissions": [],
                                "groups": []}},
                 status=204)

        # Roles Grant Permission
        rsps.add(responses.POST,
                 "%s/roles/%s/permissions" % (base_url, role_id),
                 json={"permissions": {"grant": ["manage_bananas"]}},
                 status=200)

        # Roles Revoke Permission
        rsps.add(responses.POST,
                 "%s/roles/%s/permissions" % (base_url, role_id),
                 json={"permissions": {"revoke": ["manage_bananas"]}},
                 status=200)

        # Permissions Index
        rsps.add(responses.GET,
                 "%s/permissions" % base_url,
                 json={"permissions": [
                        {"id": "a2f5ce6f-7097-4e25-9be5-525b102f57ef",
                         "name": "manage_roles",
                         "bundle": "operable"},
                        {"id": "c567de04-63fd-49c7-b675-9c6c8926640c",
                         "name": "manage_users",
                         "bundle": "operable"},
                        {"id": "d51f0cd3-8040-4174-8156-291a1930ff27",
                         "name": "manage_bananas",
                         "bundle": "site"}]},
                 status=200)

        yield rsps


def test_role_list(cogctl):
    result = cogctl(role.role)

    assert result.exit_code == 0
    assert result.output == """\
NAME    ID
monkey  c7eab02d-cfcb-4a99-a42c-9cfe5deb24a2
second  caf9f4d3-fb11-4cf9-96d1-eafa7cbc858b
"""


def test_role_create(cogctl):
    result = cogctl(role.create, ["new_monkey"])

    assert result.exit_code == 0
    assert result.output == """\
Name         new_monkey
ID           c7eab02d-cfcb-4a99-a42c-9cfe5deb24a2
Permissions
Groups
"""


def test_role_create_with_already_taken_name(cogctl):
    result = cogctl(role.create, ["monkey"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: create [OPTIONS] NAME

Error: Invalid value for "name": Role with name "monkey" already exists
"""


def test_role_info(cogctl):
    result = cogctl(role.info, ["monkey"])

    assert result.exit_code == 0
    assert result.output == """\
Name         monkey
ID           c7eab02d-cfcb-4a99-a42c-9cfe5deb24a2
Permissions  manage_roles
Groups       robots
"""


def test_role_info_with_invalid_role(cogctl):
    result = cogctl(role.info, ["fake_role"])

    assert not result.exit_code == 0

    bad_param = "Invalid value for \"role\""
    error = "\"fake_role\" was not found"
    assert "Error: %s: %s" % (bad_param, error) in result.output


def test_role_rename(cogctl):
    result = cogctl(role.rename, ["monkey", "cheeseburger"])

    assert result.exit_code == 0
    assert result.output == """\
Name         cheeseburger
ID           c7eab02d-cfcb-4a99-a42c-9cfe5deb24a2
Permissions  manage_roles
Groups       robots
"""


def test_role_delete(cogctl):
    result = cogctl(role.delete, ["monkey"])

    assert result.exit_code == 0
    assert result.output == ""


def test_role_grant(cogctl):
    result = cogctl(role.grant, ["monkey", "manage_bananas"])

    assert result.exit_code == 0
    assert result.output == ""


def test_grant_with_fully_namespaced_permission(cogctl):
    result = cogctl(role.grant, ["monkey", "operable:manage_roles"])
    assert result.exit_code == 0
    assert result.output == ""


def test_grant_with_fully_namespaced_but_nonexistent_permission(cogctl):
    result = cogctl(role.grant, ["monkey", "operable:manage_stuff"])
    assert result.exit_code == 2
    assert result.output == """\
Usage: grant [OPTIONS] ROLE PERMISSION

Error: Invalid value for "permission": "operable:manage_stuff" was not found
"""


def test_role_revoke(cogctl):
    result = cogctl(role.revoke, ["monkey", "manage_bananas"])

    assert result.exit_code == 0
    assert result.output == ""

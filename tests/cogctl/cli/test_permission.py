import pytest
from cogctl.cli import permission
import responses


@pytest.fixture(autouse=True)
def mocks(request, cli_state):
    with responses.RequestsMock(assert_all_requests_are_fired=False) as rsps:
        permission_id = "bd8fbe24-14aa-470e-a5ac-e0b0a104f257"
        base_url = "%s/v1" % cli_state.profile["url"]

        # Token
        rsps.add(responses.POST,
                 "%s/token" % base_url,
                 json={"token": {"value": "lolwut"}},
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
                        {"id": permission_id,
                         "name": "test_perm",
                         "bundle": "site"}]},
                 status=200)

        # Permissions Create
        rsps.add(responses.POST,
                 "%s/permissions" % base_url,
                 json={"permission": {"id": "44f89553-2a6b-4dfe-995c-d15a064e3008", # noqa
                                      "name": "another_perm",
                                      "bundle": "site"}},
                 status=201)

        # Permissions Show
        rsps.add(responses.POST,
                 "%s/permissions/%s" % (base_url, permission_id),
                 json={"permission": {"id": permission_id,
                                      "name": "test_perm",
                                      "bundle": "site"}},
                 status=201)

        # Permissions Delete
        rsps.add(responses.DELETE,
                 "%s/permissions/%s" % (base_url, permission_id),
                 json={"permission": {"id": permission_id,
                                      "name": "test_perm",
                                      "bundle": "site"}},
                 status=204)

        yield rsps


def test_permission_list(cogctl):
    result = cogctl(permission.permission)

    assert result.exit_code == 0
    assert result.output == """\
NAME                   ID
operable:manage_roles  a2f5ce6f-7097-4e25-9be5-525b102f57ef
operable:manage_users  c567de04-63fd-49c7-b675-9c6c8926640c
site:test_perm         bd8fbe24-14aa-470e-a5ac-e0b0a104f257
"""


def test_permission_create(cogctl):
    result = cogctl(permission.create, ["another"])

    assert result.exit_code == 0
    assert result.output == """\
Name  site:another_perm
ID    44f89553-2a6b-4dfe-995c-d15a064e3008
"""


def test_permission_create_with_non_site_bundle(cogctl):
    result = cogctl(permission.create, ["ec2:admin"])

    assert not result.exit_code == 0

    bad_param = "Invalid value for \"name\""
    error = "Permissions must be created in the \"site\" bundle (e.g. site:deploy)" # noqa
    assert "Error: %s: %s" % (bad_param, error) in result.output


def test_permission_create_with_existing_permission(cogctl):
    result = cogctl(permission.create, ["site:test_perm"])

    assert not result.exit_code == 0

    bad_param = "Invalid value for \"name\""
    error = "Permission \"site:test_perm\" already exists"
    assert "Error: %s: %s" % (bad_param, error) in result.output


def test_permission_info(cogctl):
    result = cogctl(permission.info, ["test_perm"])

    assert result.exit_code == 0
    assert result.output == """\
Name  site:test_perm
ID    bd8fbe24-14aa-470e-a5ac-e0b0a104f257
"""


def test_permission_info_with_full_name(cogctl):
    result = cogctl(permission.info, ["site:test_perm"])

    assert result.exit_code == 0
    assert result.output == """\
Name  site:test_perm
ID    bd8fbe24-14aa-470e-a5ac-e0b0a104f257
"""


def test_permission_info_with_invalid_permission(cogctl):
    result = cogctl(permission.info, ["missing_perm"])

    assert not result.exit_code == 0

    bad_param = "Invalid value for \"permission\""
    error = "Permission \"missing_perm\" not found"
    assert "Error: %s: %s" % (bad_param, error) in result.output


def test_permission_delete(cogctl):
    result = cogctl(permission.delete, ["test_perm"])

    assert result.exit_code == 0
    assert result.output == ""

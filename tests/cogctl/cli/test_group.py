import json
import re
from urllib.parse import urlparse
import pytest
import cogctl.cli.group as group
import responses


# FIXTURES -------------------------------------------------------------------

@pytest.fixture(autouse=True)
def mocks(request, cli_state):
    with responses.RequestsMock(assert_all_requests_are_fired=False) as rsps:
        # Token
        # Is called with each set of requests
        rsps.add(responses.POST,
                 cli_state.profile["url"] + "/v1/token",
                 json={"token": {"value": "lolwut"}},
                 status=200)
        # Groups Index
        # Gets called fairly often since because we manually search for
        # groups by name
        rsps.add(responses.GET,
                 cli_state.profile["url"] + "/v1/groups",
                 json={"groups": [{"id": "1234567890",
                                   "name": "group1",
                                   "members": {
                                       "users": [{"username": "bob"},
                                                 {"username": "admin"}],
                                       "roles": [{"name": "role1"},
                                                 {"name": "role2"}]}},
                                  {"id": "2345678901",
                                   "name": "group2"}]},
                 status=200)
        # Groups Create
        rsps.add(responses.POST,
                 cli_state.profile["url"] + "/v1/groups",
                 json={"group": {"id": "3456789012",
                                 "name": "new_group",
                                 "members": {"users": [],
                                             "roles": []}}},
                 status=201)
        # Groups Delete
        rsps.add(responses.DELETE,
                 cli_state.profile["url"] + "/v1/groups/1234567890",
                 status=204)
        # Users Index
        # Called to determine if a username exists
        rsps.add(responses.GET,
                 cli_state.profile["url"] + "/v1/users",
                 json={"users": [{"username": "bob"},
                                 {"username": "sally"},
                                 {"username": "jess"},
                                 {"username": "stan"}]},
                 status=200)
        # Roles Index
        # Called to determine if a role exists
        rsps.add(responses.GET,
                 cli_state.profile["url"] + "/v1/roles",
                 json={"roles": [{"name": "role1"},
                                 {"name": "role2"},
                                 {"name": "role3"},
                                 {"name": "role4"}]},
                 status=200)
        # Group Show
        rsps.add(responses.GET,
                 cli_state.profile["url"] + "/v1/groups/1234567890",
                 json={"group": {"id": "1234567890",
                                 "name": "group1",
                                 "members": {"users": [],
                                             "roles": [{"name": "role1"},
                                                       {"name": "role2"}]}}},
                 status=200)
        rename_group(cli_state, rsps)
        update_users(cli_state, rsps)
        update_roles(cli_state, rsps)
        yield rsps

# REQUEST HELPERS ------------------------------------------------------------


def update_users(state, rsps):
    """
    Adds or removes users from a group.
    This function assumes the group being updated already has
    two users, "sally" and "jess". Users are added and removed,
    and the modified group is returned.
    """

    def callback_fn(request):
        req = json.loads(request.body.decode('utf-8'))
        id = urlparse(request.url).path.split("/")[3]

        # Make sure we have a 'users' key
        # We don't explicitly need to assert here, but it let's us fail
        # early and gives a better hint that the request json is malformed.
        user_spec = req.get('users')
        assert user_spec is not None

        users = ["sally", "jess"]

        to_add = user_spec.get('add')
        to_del = user_spec.get('remove')

        if to_add:
            users = users + to_add

        if to_del:
            users = list(set(users).difference(set(to_del)))

        # Make sure the list does not contain duplicates
        # We do this just ensure that cogctl is removing duplicate
        # entries before making the request.
        assert_unique(users)

        # Sort for test consistency
        # Not sure if we get data back from the api sorted or not,
        # but this just prevents the tests from failing randomly
        # when the users come back in the wrong order.
        users.sort()

        headers = {'content-type': 'application/json'}
        data = {"group":
                {"id": id,
                 "name": "group1",
                 "members": {"users": [{"username": u} for u in users],
                             "roles": []}}}

        return (200, headers, json.dumps(data))

    url = re.compile(state.profile['url'] + '\/v1\/groups\/\d+\/users$')
    rsps.add_callback(
            responses.POST,
            url,
            callback=callback_fn,
            content_type="application/json")


def update_roles(state, rsps):
    """
    Adds or removes roles from a group.
    This is similar to update_users with one major exception, it returns the
    list of roles instead of the updated group. As a result cogctl needs to
    make an extra request to get the updated group. So when using this function
    you will need to manually specify what the new group's json looks like. See
    'test_group_grant_roles' for an example. This is probably something that
    needs to change in Cog's api, but for now we work with what we have.
    """

    def callback_fn(request):
        req = json.loads(request.body.decode('utf-8'))

        # Make sure we have a 'roles' key
        # We don't explicitly need to assert here, but it let's us fail
        # early and gives a better hint that the request json is malformed.
        role_spec = req.get('roles')
        assert role_spec is not None

        roles = ["role3", "role4"]

        to_add = role_spec.get('add')
        to_del = role_spec.get('remove')

        if to_add:
            roles = roles + to_add

        if to_del:
            roles = list(set(roles).difference(set(to_del)))

        # Make sure the list does not contain duplicates
        # We do this just ensure that cogctl is removing duplicate
        # entries before making the request.
        assert_unique(roles)

        # Sort for test consistency
        # Not sure if we get data back from the api sorted or not,
        # but this just prevents the tests from failing randomly
        # when the users come back in the wrong order.
        roles.sort()

        headers = {'content-type': 'application/json'}
        data = {"roles": [{"id": "roleid_%s" % r,
                           "name": r} for r in roles]}

        return (200, headers, json.dumps(data))

    url = re.compile(state.profile['url'] + '\/v1\/groups\/\d+\/roles$')
    rsps.add_callback(
            responses.POST, url,
            callback=callback_fn,
            content_type="application/json")


def assert_unique(lst):
    """
    Asserts that a list contains unique values
    """
    lst1 = list(set(lst))
    lst2 = lst
    lst1.sort()
    lst2.sort()

    # Sorting and comparing the actual lists instead of comparing the list's
    # size gives a more informative error message when there is a failure.
    assert lst1 == lst2


def rename_group(state, rsps):

    def callback_fn(request):
        req = json.loads(request.body.decode('utf-8'))
        id = urlparse(request.url).path.split("/")[3]

        # Make sure we have a 'group' key
        group = req.get('group')
        assert group is not None

        # Make sure we have a name key
        name = group.get('name')
        assert name is not None

        headers = {'content-type': 'application/json'}
        data = {"group": {"id": id,
                          "name": name,
                          "members": {"users": [],
                                      "roles": []}}}

        return (200, headers, json.dumps(data))

    url = re.compile(state.profile['url'] + '\/v1\/groups\/\d+$')
    rsps.add_callback(
            responses.PUT,
            url,
            callback=callback_fn,
            content_type="application/json")


# TESTS ----------------------------------------------------------------------

def test_group_index(cogctl):
    result = cogctl(group.group)

    assert result.exit_code == 0
    assert result.output == """\
NAME    ID
group1  1234567890
group2  2345678901
"""


def test_group_create(cogctl):
    result = cogctl(group.create, ["new_group"])

    assert result.exit_code == 0
    assert result.output == """\
ID     3456789012
Name   new_group
Users
Roles
"""


def test_group_info(cogctl):
    result = cogctl(group.info, ["group1"])

    assert result.exit_code == 0
    assert result.output == """\
ID     1234567890
Name   group1
Users  bob, admin
Roles  role1, role2
"""


def test_group_info_with_invalid_group(cogctl):
    result = cogctl(group.info, ["fake_group"])

    assert not result.exit_code == 0
    assert 'Error: Invalid value for "group": "fake_group" was not found' in result.output  # noqa: E501


def test_group_rename(cogctl):
    result = cogctl(group.rename, ["group1", "renamed_group1"])

    assert result.exit_code == 0
    assert result.output == """\
ID     1234567890
Name   renamed_group1
Users
Roles
"""


def test_group_rename_with_invalid_group(cogctl):
    result = cogctl(group.rename, ["fake_group", "renamed_group"])

    assert not result.exit_code == 0
    assert 'Error: Invalid value for "group": "fake_group" was not found' in result.output  # noqa: E501


def test_group_rename_with_non_unique_name(cogctl):
    result = cogctl(group.rename, ["group1", "group2"])

    assert not result.exit_code == 0
    assert 'Error: Invalid value for "new_name": Group with name "group2" already exists' in result.output  # noqa: E501


def test_group_delete(cogctl):
    result = cogctl(group.delete, ["group1"])

    assert result.exit_code == 0
    assert result.output == """\
ID     1234567890
Name   group1
Users  bob, admin
Roles  role1, role2
"""


def test_group_delete_with_invalid_group(cogctl):
    result = cogctl(group.delete, ["fake_group"])

    assert not result.exit_code == 0
    assert 'Error: Invalid value for "group": "fake_group" was not found' in result.output  # noqa: E501


def test_group_add_users(cogctl):
    result = cogctl(group.add, ["group1", "bob", "stan"])

    assert result.exit_code == 0
    assert result.output == """\
ID     1234567890
Name   group1
Users  bob, jess, sally, stan
Roles
"""


def test_group_add_users_with_duplicate_valid_names(cogctl):
    """
    Duplicate usernames should be ignored
    """
    result = cogctl(group.add, ["group1", "bob", "stan", "bob"])

    assert result.exit_code == 0
    assert result.output == """\
ID     1234567890
Name   group1
Users  bob, jess, sally, stan
Roles
"""


def test_group_add_users_with_an_invalid_user(cogctl):
    result = cogctl(group.add, ["group1", "bob", "fakeBob"])

    assert not result.exit_code == 0
    assert 'Error: Invalid value for "usernames": The following user/s could not be found: fakeBob' in result.output  # noqa: E501


def test_group_remove_users(cogctl):
    result = cogctl(group.remove, ["group1", "sally", "jess", "--yes"])

    assert result.exit_code == 0
    assert result.output == """\
ID     1234567890
Name   group1
Users
Roles
"""


def test_group_remove_users_with_invalid_user(cogctl):
    result = cogctl(group.remove, ["group1", "bob", "fakeBob", "--yes"])

    assert not result.exit_code == 0
    assert 'Error: Invalid value for "usernames": The following user/s could not be found: fakeBob' in result.output  # noqa: E501


def test_group_remove_users_when_confirmation_fails(cogctl):
    result = cogctl(group.remove, ["group1", "bob", "stan"], input="N")

    assert result.exit_code == 1
    assert 'Aborted!' in result.output


# We're injecting cli_state and mocks here because of the way cog's api
# works. When adding roles to groups Cog returns the roles and not the
# updated group. This means that we have to make an additional request
# to get the updated group and thus creates some remote state. Hopefully
# changes in the future but for now we are just adding another response
# to the mocks with what the updated group should look like specifically
# for this test.
def test_group_grant_roles(cogctl, cli_state, mocks):
    mocks.add(responses.GET,
              cli_state.profile["url"] + "/v1/groups/2345678901",
              json={"group": {"id": "2345678901",
                              "name": "group2",
                              "members": {"users": [],
                                          "roles": [{"name": "role1"},
                                                    {"name": "role2"}]}}},
              status=200)
    result = cogctl(group.grant, ["group2", "role1", "role2"])

    assert result.exit_code == 0
    assert result.output == """\
ID     2345678901
Name   group2
Users
Roles  role1, role2
"""


# Injecting cli_state and mocks to get around a quirk in the Cog api. To
# learn more read the comment above for `test_group_grant_roles`.
def test_group_grant_roles_with_duplicate_names(cogctl, cli_state, mocks):
    mocks.add(responses.GET,
              cli_state.profile["url"] + "/v1/groups/2345678901",
              json={"group": {"id": "2345678901",
                              "name": "group2",
                              "members": {"users": [],
                                          "roles": [{"name": "role1"},
                                                    {"name": "role2"}]}}},
              status=200)
    result = cogctl(group.grant, ["group2", "role1", "role2", "role1"])

    assert result.exit_code == 0
    assert result.output == """\
ID     2345678901
Name   group2
Users
Roles  role1, role2
"""


def test_group_grant_roles_with_invalid_role(cogctl):
    result = cogctl(group.grant, ["group1", "role1", "fakerole"])

    assert not result.exit_code == 0
    assert 'Error: Invalid value for "roles": The following role/s could not be found: fakerole' in result.output  # noqa: E501


# Injecting cli_state and mocks to get around a quirk in the Cog api. To
# learn more read the comment above for `test_group_grant_roles`.
def test_group_revoke_roles(cogctl, cli_state, mocks):
    mocks.add(responses.GET,
              cli_state.profile["url"] + "/v1/groups/2345678901",
              json={"group": {"id": "2345678901",
                              "name": "group2",
                              "members": {"users": [],
                                          "roles": []}}},
              status=200)

    result = cogctl(group.revoke, ["group2", "role1", "role2", "--yes"])

    assert result.exit_code == 0
    assert result.output == """\
ID     2345678901
Name   group2
Users
Roles
"""


def test_group_revoke_roles_with_invalid_role(cogctl):
    result = cogctl(group.revoke, ["group1", "role1", "fakerole", "--yes"])

    assert not result.exit_code == 0
    assert 'Error: Invalid value for "roles": The following role/s could not be found: fakerole' in result.output  # noqa: E501


def test_group_revoke_roles_when_confirmation_fails(cogctl):
    result = cogctl(group.revoke, ["group1", "role1", "role2"], input="N")

    assert result.exit_code == 1
    assert 'Aborted!' in result.output

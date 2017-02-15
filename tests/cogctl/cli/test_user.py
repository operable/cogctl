import pytest
from cogctl.cli import user
import responses
import json


# FIXTURES -------------------------------------------------------------------

@pytest.fixture(autouse=True)
def mocks(request, cli_state):
    with responses.RequestsMock(assert_all_requests_are_fired=False) as rsps:
        base_url = "%s/v1" % cli_state.profile["url"]

        # Token
        rsps.add(responses.POST,
                 "%s/token" % base_url,
                 json={"token": {"value": "lolwut"}},
                 status=200)

        # User index
        rsps.add(responses.GET,
                 "%s/users" % base_url,
                 json={"users": [{"username": "admin",
                                  "first_name": "Cog",
                                  "last_name": "McCoggerson",
                                  "email_address": "cog@operable.io",
                                  "id": "1",
                                  "groups": []},
                                 {"username": "steve",
                                  "first_name": "Steve",
                                  "last_name": "Bayberry",
                                  "email_address": "steve@bob.com",
                                  "id": "2",
                                  "groups": []}]},
                 status=200)

        # User Create
        rsps.add(responses.POST,
                 "%s/users" % base_url,
                 json={"user": {"username": "bob",
                                "first_name": "Bob",
                                "last_name": "Fox",
                                "email_address": "bob@bob.com",
                                "id": "1234567890",
                                "groups": []}},
                 status=201)

        # User Show
        rsps.add(responses.GET,
                 "%s/users/1" % base_url,
                 json={"user": {"username": "admin",
                                "first_name": "Cog",
                                "last_name": "McCoggerson",
                                "email_address": "cog@operable.io",
                                "id": "1",
                                "groups": []}},
                 status=201)

        # User Delete
        rsps.add(responses.DELETE,
                 "%s/users/2" % base_url,
                 status=204)

        # User password reset request
        rsps.add(responses.POST,
                 "%s/users/reset-password" % base_url,
                 status=204)

        # User password reset
        rsps.add(responses.PUT,
                 "%s/users/reset-password/fake-token" % base_url,
                 status=204)

        def update_user_callback_fn(request):
            req = json.loads(request.body.decode('utf-8'))

            updates = req.get('user')
            assert updates is not None

            user = {"username": "steve",
                    "first_name": "Steve",
                    "last_name": "Bayberry",
                    "email_address": "steve@bob.com",
                    "id": "2",
                    "groups": []}

            user.update(updates)

            headers = {'content-type': 'application/json'}
            data = {"user": user}

            return (200, headers, json.dumps(data))

        rsps.add_callback(
                responses.PUT,
                "%s/v1/users/2" % cli_state.profile['url'],
                callback=update_user_callback_fn,
                content_type="application/json")

        yield rsps


def test_get_users(cogctl):
    result = cogctl(user.user)

    assert result.exit_code == 0
    assert result.output == """\
USERNAME  FULL NAME        EMAIL ADDRESS
admin     Cog McCoggerson  cog@operable.io
steve     Steve Bayberry   steve@bob.com
"""


def test_create_user(cogctl):
    result = cogctl(user.create,
                    ["bob",
                     "--first-name", "Bob",
                     "--last-name", "Fox",
                     "--email", "bob@bob.com",
                     "--password", "password"])

    assert result.exit_code == 0
    assert result.output == """\
ID          1234567890
Username    bob
Email       bob@bob.com
First Name  Bob
Last Name   Fox
Groups
"""


def test_create_user_with_inputs(cogctl):
    result = cogctl(user.create,
                    ["bob", "--first-name", "Bob", "--last-name", "Fox"],
                    input="bob@bob.com\npassword\npassword")

    assert result.exit_code == 0
    assert result.output == """\
Email: bob@bob.com
Password: 
Repeat for confirmation: 
ID          1234567890
Username    bob
Email       bob@bob.com
First Name  Bob
Last Name   Fox
Groups
""" # noqa:  W291


def test_user_info(cogctl):
    result = cogctl(user.info, ["admin"])

    assert result.exit_code == 0
    assert result.output == """\
ID          1
Username    admin
Email       cog@operable.io
First Name  Cog
Last Name   McCoggerson
Groups
"""


def test_user_update(cogctl):
    result = cogctl(user.update, ["steve", "--first-name", "Bill"])

    assert result.exit_code == 0
    assert result.output == """\
ID          2
Username    steve
Email       steve@bob.com
First Name  Bill
Last Name   Bayberry
Groups
"""


def test_user_update_with_no_fields(cogctl):
    result = cogctl(user.update, ["steve"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: update [OPTIONS] USER

Error: You must specify a field to update.
"""


def test_user_update_password(cogctl):
    result = cogctl(user.update,
                    ["steve", "--password", "password"])

    assert result.exit_code == 0
    assert result.output == """\
ID          2
Username    steve
Email       steve@bob.com
First Name  Steve
Last Name   Bayberry
Groups
"""  # noqa: W291


def test_delete_user(cogctl):
    result = cogctl(user.delete, ["steve", "--yes"])

    assert result.exit_code == 0
    assert result.output == """\
ID          2
Username    steve
Email       steve@bob.com
First Name  Steve
Last Name   Bayberry
Groups
"""


def test_delete_user_with_prompt(cogctl):
    result = cogctl(user.delete, ["steve"], input="y\n")

    assert result.exit_code == 0
    assert result.output == """\
Are you sure? [y/N]: y
ID          2
Username    steve
Email       steve@bob.com
First Name  Steve
Last Name   Bayberry
Groups
"""


def test_abort_delete_user(cogctl):
    result = cogctl(user.delete, ["steve"], input="N\n")

    assert result.exit_code == 1
    assert result.output == """\
Are you sure? [y/N]: N
Aborted!
"""


def test_password_reset_request(cogctl):
    result = cogctl(user.password_reset_request, ["steve@bob.com"])

    assert result.exit_code == 0
    assert result.output == """\
Requesting password reset
"""


def test_password_reset(cogctl):
    result = cogctl(user.password_reset, ["fake-token", "new_password"])

    assert result.exit_code == 0
    assert result.output == """\
Resetting password
"""

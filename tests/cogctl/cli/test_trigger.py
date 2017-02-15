import pytest
import cogctl.cli.trigger as trigger
import responses

# FIXTURES -------------------------------------------------------------------

USER_ID = 'aacd5af0-4d64-4921-85bc-dfc26e66862c'
TRIGGER_IDS = ['5aa03fa7-62e0-48b6-9570-4d0546b02ebd',
               '4aba9adb-0e86-412c-91d2-3cbffa2cb7f7',
               '12e9bec9-c44a-4a2b-828c-77b2939487b3',
               'e2f0d7f3-af09-4445-a99e-cfbf8fb66803']


def invoke_url(index):
    return "https://foo.com:8888/triggers/" + TRIGGER_IDS[index]


@pytest.fixture()
def mocks(request, cli_state):
    with responses.RequestsMock(assert_all_requests_are_fired=False) as resps:
        # Token
        # Is called with each set of requests
        resps.add(responses.POST,
                  cli_state.profile["url"] + "/v1/token",
                  json={"token": {"value": "lulz"}},
                  status=200)
        # User by name (success)
        resps.add(responses.GET,
                  cli_state.profile["url"] + "/v1/users?username=zdavid",
                  match_querystring=True,
                  json={"user": {"id": USER_ID,
                                 "first_name": "Ziva",
                                 "last_name": "David",
                                 "username": "zdavid"}},
                  status=200)
        # User by name (failure)
        resps.add(responses.GET,
                  cli_state.profile["url"] + "/v1/users?username=tdinozzo",
                  match_querystring=True,
                  json={"error": "No such user"},
                  status=404)
        # Trigger create
        resps.add(responses.POST,
                  cli_state.profile["url"] + "/v1/triggers",
                  json={"trigger": {"id": TRIGGER_IDS[1],
                                    "name": "bar",
                                    "timeout_sec": 60,
                                    "as_user": None,
                                    "pipeline": "foo | bar | baz",
                                    "invocation_url": invoke_url(1),
                                    "enabled": False}},
                  status=201)
        # Trigger get by name (success)
        resps.add(responses.GET,
                  cli_state.profile["url"] + "/v1/triggers?name=foo",
                  match_querystring=True,
                  json={"triggers": [{"id": TRIGGER_IDS[0],
                                      "name": "foo",
                                      "timeout_sec": 60,
                                      "as_user": None,
                                      "pipeline": "foo | bar | baz",
                                      "invocation_url": invoke_url(0),
                                      "enabled": False}]},
                  status=200)
        # Trigger get by name (failure)
        resps.add(responses.GET,
                  cli_state.profile["url"] + "/v1/triggers?name=bar",
                  match_querystring=True,
                  json={"triggers": []},
                  status=200)
        resps.add(responses.GET,
                  cli_state.profile["url"] + "/v1/triggers?name=bar2",
                  match_querystring=True,
                  json={"triggers": []},
                  status=200)
        # Update trigger
        resps.add(responses.PUT,
                  cli_state.profile["url"] + "/v1/triggers/" + TRIGGER_IDS[0],
                  json={"trigger": {"id": TRIGGER_IDS[1],
                                    "name": "bar2",
                                    "timeout_sec": 70,
                                    "as_user": "zdavid",
                                    "pipeline": "baz | bar | foo",
                                    "invocation_url": invoke_url(0),
                                    "enabled": True}},
                  status=200),
        # Delete trigger
        resps.add(responses.DELETE,
                  cli_state.profile["url"] + "/v1/triggers/" + TRIGGER_IDS[0],
                  status=204)
        # List all triggers
        all_triggers = []
        for id in TRIGGER_IDS[1:]:
            all_triggers.append({"id": id,
                                 "name": "foo_" + id[0:2],
                                 "timeout_sec": 60,
                                 "as_user": None,
                                 "pipeline": "foo | bar | baz",
                                 "enabled": False})
        resps.add(responses.GET,
                  cli_state.profile["url"] + "/v1/triggers",
                  json={"triggers": all_triggers},
                  status=200)
        yield resps


def test_list_all_triggers(cogctl, mocks):
    result = cogctl(trigger.trigger)
    assert 0 == result.exit_code
    assert """\
NAME    PIPELINE         ENABLED
foo_4a  foo | bar | baz  False
foo_12  foo | bar | baz  False
foo_e2  foo | bar | baz  False
""" == result.output


def test_create_trigger_with_existing_name(cogctl, mocks):
    result = cogctl(trigger.create, ["foo", "help"])
    assert 2 == result.exit_code
    assert """\
Usage: create [OPTIONS] NAME PIPELINE

Error: Invalid value for "name": Trigger "foo" already exists
""" == result.output


def test_create_trigger_with_missing_user(cogctl, mocks):
    result = cogctl(trigger.create, ["my_trigger", "help",
                                     "--as-user", "tdinozzo"])
    assert 2 == result.exit_code
    assert """\
Usage: create [OPTIONS] NAME PIPELINE

Error: User \"tdinozzo\" was not found
""" == result.output


def test_create_trigger_with_bad_timeout(cogctl, mocks):
    result = cogctl(trigger.create, ["my_trigger", "help",
                                     "--timeout", "sixty"])
    assert 2 == result.exit_code
    assert """\
Usage: create [OPTIONS] NAME PIPELINE

Error: Invalid value for \"--timeout\": \"sixty\" is not a valid integer
""" == result.output


def test_create_trigger(cogctl, mocks):
    result = cogctl(trigger.create, ["bar", "foo | bar | baz"])
    assert 0 == result.exit_code
    assert """\
Name      bar
Pipeline  foo | bar | baz
Enabled   False
""" == result.output


def test_update_trigger(cogctl, mocks):
    result = cogctl(trigger.update, ["foo", "--as-user", "zdavid",
                                     "--timeout", "70",
                                     "--name", "bar2",
                                     "--pipeline", "baz | bar | foo",
                                     "--enable"])
    assert 0 == result.exit_code
    assert """\
Name            bar2
Pipeline        baz | bar | foo
Enabled         True
As User         zdavid
Timeout Sec     70
Invocation Url  https://foo.com:8888/triggers/5aa03fa7-62e0-48b6-9570-4d0546b02ebd
""" == result.output


def test_update_trigger_with_bad_enable_flags(cogctl, mocks):
    result = cogctl(trigger.update, ["foo", "--enable", "--disable"])
    assert 2 == result.exit_code
    assert """\
Usage: update [OPTIONS] TRIGGER_NAME

Error: Trigger cannot be both enabled and disabled
""" == result.output


def test_delete_trigger_missing_name(cogctl, mocks):
    result = cogctl(trigger.delete, ["bar", "--force"])
    assert 1 == result.exit_code
    assert """\
Error: Trigger \"bar\" not found
""" == result.output


def test_delete_trigger_without_force_causes_prompt(cogctl, mocks):
    result = cogctl(trigger.delete, ["foo"])
    assert 1 == result.exit_code
    assert result.output.startswith("Are you sure? [y/N]:")


def test_delete_trigger(cogctl, mocks):
    result = cogctl(trigger.delete, ["foo", "--force"])
    assert 0 == result.exit_code
    assert result.output.startswith('Trigger "foo" deleted')


def test_trigger_info(cogctl, mocks):
    result = cogctl(trigger.info, ["foo"])
    assert 0 == result.exit_code
    assert """\
Name            foo
Pipeline        foo | bar | baz
Enabled         False
As User         None
Timeout Sec     60
Invocation Url  https://foo.com:8888/triggers/5aa03fa7-62e0-48b6-9570-4d0546b02ebd
""" == result.output


def test_trigger_info_with_bad_name(cogctl, mocks):
    result = cogctl(trigger.info, ["bar"])
    print(result.output)
    assert 1 == result.exit_code
    assert """\
Error: Trigger \"bar\" not found
""" == result.output

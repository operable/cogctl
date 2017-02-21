import json
import pytest
from cogctl.cli import chat_handle
import responses


@pytest.fixture(autouse=True)
def mocks(request, cli_state):
    with responses.RequestsMock(assert_all_requests_are_fired=False) as rsps:
        base_url = "%s/v1" % cli_state.profile["url"]
        user_id = "b370f1cd-3890-4be2-ad87-38218cc81aa6"
        chat_handle_id = "cf6f2aa9-8856-4d9a-84c1-7749a2f34c15"

        # Token
        rsps.add(responses.POST,
                 "%s/token" % base_url,
                 json={"token": {"value": "lolwut"}},
                 status=200)

        # Chat Handle Index
        rsps.add(responses.GET,
                 "%s/chat_handles" % base_url,
                 json={"chat_handles": [{
                         "id": "c63933ec-cf57-4ae3-8212-d0353a0f7e0c",
                         "handle": "cogerson",
                         "chat_provider_user_id": "U024BE7LH",
                         "user": {
                             "id": "e4cb9af5-e14f-4ed4-b74e-b93f077d7e84",
                             "username": "mrcogerson"},
                         "chat_provider": {
                             "id": "dad4fd69-0871-400a-8f1d-611767de26ba",
                             "name": "slack"}},
                        {"id": "40963d8a-4dc5-45f4-8bb1-85bc4c8e6167",
                         "handle": "derpster",
                         "chat_provider_user_id": "U024BLEH3",
                         "user": {
                             "id": "940af9b6-aaf0-4f8f-bd98-d5e49b9f9390",
                             "username": "derpster"},
                         "chat_provider": {
                             "id": "dad4fd69-0871-400a-8f1d-611767de26ba",
                             "name": "slack"}},
                        {"id": chat_handle_id,
                         "handle": "vansterminator",
                         "chat_provider_user_id": "U025BE7LH",
                         "user": {
                             "id": user_id,
                             "username": "vanstee"},
                         "chat_provider": {
                             "id": "dad4fd69-0871-400a-8f1d-611767de26ba",
                             "name": "slack"}}]},
                 status=200)

        # Chat Handle Create
        def create_callback(req):
            payload = json.loads(req.body.decode())

            # Simulate an already-taken handle
            if payload["chat_handle"]["handle"] == "THIS_NAME_ALREADY_TAKEN":
                body = {"errors":
                        {"handle":
                         ["Another user has claimed this chat handle"]}}
                return (422,
                        {'content-type': 'application/json'},
                        json.dumps(body))

            body = {"chat_handle": {
                "id": chat_handle_id,
                "handle": "vansterminator",
                "chat_provider_user_id": "U025BE7LH",
                "user": {
                    "id": "acd4da74-8b6d-43ce-990e-63b62700f734",
                    "username": "vanstee"},
                "chat_provider": {
                    "id": "dad4fd69-0871-400a-8f1d-611767de26ba",
                    "name": "slack"}}}

            return (201,
                    {'content-type': 'application/json'},
                    json.dumps(body))

        rsps.add_callback(responses.POST,
                          "%s/users/%s/chat_handles" % (base_url, user_id),
                          callback=create_callback,
                          content_type="application/json")

        # Chat Handle Delete
        rsps.add(responses.DELETE,
                 "%s/chat_handles/%s" % (base_url, chat_handle_id),
                 json={"chat_handle": {
                         "id": chat_handle_id,
                         "handle": "vansterminator",
                         "chat_provider_user_id": "U025BE7LH",
                         "user": {
                             "id": "acd4da74-8b6d-43ce-990e-63b62700f734",
                             "username": "vanstee"},
                         "chat_provider": {
                             "id": "dad4fd69-0871-400a-8f1d-611767de26ba",
                             "name": "slack"}}},
                 status=201)

        # Users Index
        rsps.add(responses.GET,
                 "%s/users" % base_url,
                 json={"users": [{
                           "id": user_id,
                           "username": "vanstee"}]},
                 status=200)

        yield rsps


def test_chat_handle_list(cogctl):
    result = cogctl(chat_handle.chat_handle)

    assert result.exit_code == 0
    assert result.output == """\
USER        CHAT PROVIDER  HANDLE
mrcogerson  slack          cogerson
derpster    slack          derpster
vanstee     slack          vansterminator
"""


def test_chat_handle_create(cogctl):
    result = cogctl(chat_handle.create, ["vanstee", "slack", "vansterminator"])

    assert result.exit_code == 0
    assert result.output == """\
User           vanstee
Chat Provider  slack
Handle         vansterminator
"""


def test_chat_handle_already_taken(cogctl):
    result = cogctl(chat_handle.create, ["vanstee", "slack",
                                         "THIS_NAME_ALREADY_TAKEN"])

    assert result.exit_code == 1
    assert result.output == """\
Error: Another user has claimed this chat handle
"""


def test_chat_handle_delete(cogctl):
    result = cogctl(chat_handle.delete, ["vanstee", "slack"])

    assert result.exit_code == 0
    assert result.output == ""

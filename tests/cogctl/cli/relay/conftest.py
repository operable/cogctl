import json
import pytest
import re
import responses


@pytest.fixture
def mocks(cli_state):
    root = cli_state.profile["url"]

    with responses.RequestsMock(assert_all_requests_are_fired=False) as r:
        r.add(responses.POST,
              root + "/v1/token",
              json={"token": {"value": "abcdef0123456789"}},
              status=201)

        def n2id(name):
            return "%s_id" % name

        def id2n(id):
            return id.replace("_id", "")

        r.add(responses.GET,
              root + "/v1/relay_groups",
              json={"relay_groups":
                    [{"id": n2id("group_1"),
                      "inserted_at": "1970-01-01T00:00:00",
                      "name": "group_1",
                      "bundles": [],
                      "relays": []},
                     {"id": n2id("group_2"),
                      "inserted_at": "1970-01-01T00:00:01",
                      "name": "group_2",
                      "bundles": [],
                      "relays": []},
                     {"id": n2id("group_3"),
                      "inserted_at": "1970-01-01T00:00:02",
                      "name": "group_3",
                      "bundles": [],
                      "relays": []},
                     {"id": n2id("group_with_bundles"),
                      "inserted_at": "1970-01-01T00:00:03",
                      "name": "group_with_bundles",
                      "bundles": [{"id": n2id("a_bundle"),
                                   "name": "a_bundle"},
                                  {"id": n2id("bundle_1"),
                                   "name": "bundle_1"}],
                      "relays": []},
                     {"id": n2id("group_with_members"),
                      "inserted_at": "1970-01-01T00:00:04",
                      "name": "group_with_members",
                      "bundles": [],
                      "relays": [{"id": n2id("a_relay"),
                                  "name": "a_relay"},
                                 {"id": n2id("another_relay"),
                                  "name": "another_relay"}]},
                     {"id": n2id("group_with_bundles_and_relays"),
                      "inserted_at": "1970-01-01T00:00:05",
                      "name": "group_with_bundles_and_relays",
                      "bundles": [{"id": n2id("a_bundle"),
                                   "name": "a_bundle"},
                                  {"id": n2id("bundle_1"),
                                   "name": "bundle_1"}],
                      "relays": [{"id": n2id("a_relay"),
                                  "name": "a_relay"},
                                 {"id": n2id("another_relay"),
                                  "name": "another_relay"}]}]},
              status=200)

        r.add(responses.GET,
              root + "/v1/relays",
              json={"relays":
                    [{"id": n2id("relay_1"),
                      "name": "relay_1"},
                     {"id": n2id("relay_2"),
                      "name": "relay_2"},
                     {"id": n2id("relay_3"),
                      "name": "relay_3"}]},
              status=200)

        r.add(responses.POST,
              root + "/v1/relay_groups",
              json={"relay_group":
                    {"id": n2id("new_group"),
                     "name": "new_group"}},
              status=201)

        headers = {'content-type': 'application/json'}

        relay_group_add_bundle_regex = re.compile("^.*/v1/relay_groups/(?P<relay_group_id>[^/].*)/(?P<thing>bundles|relays)")  # noqa: E501

        def relay_group_bundle_callback(request):
            m = re.search(relay_group_add_bundle_regex, request.url)
            thing = m.group("thing")

            req_body = json.loads(request.body.decode())
            to_add = req_body.get(thing, {}).get("add", [])
            to_remove = req_body.get(thing, {}).get("remove", [])

            relay_group_id = m.group('relay_group_id')
            relay_group_name = id2n(relay_group_id)

            if relay_group_name == "group_with_members" and thing == "relays":
                existing = [{"id": n2id("a_relay"),
                             "name": "a_relay"},
                            {"id": n2id("another_relay"),
                             "name": "another_relay"}]
            elif (relay_group_name == "group_with_bundles" and
                  thing == "bundles"):
                existing = [{"id": n2id("a_bundle"),
                             "name": "a_bundle"},
                            {"id": n2id("bundle_1"),
                             "name": "bundle_1"}]
            else:
                existing = []

            if to_add:
                things = existing + [{"id": r, "name": id2n(r)}
                                     for r in to_add]
            else:
                names_to_remove = {id2n(r) for r in to_remove}
                things = [r for r in existing
                          if r["name"] not in names_to_remove]

            body = {"relay_group":
                    {"id": relay_group_id,
                     "name": relay_group_name,
                     thing: things}}

            return (200, headers, json.dumps(body))

        r.add_callback(responses.POST,
                       relay_group_add_bundle_regex,
                       callback=relay_group_bundle_callback,
                       content_type="application/json")

        relay_group_delete_regex = re.compile("^.*/v1/relay_groups/(?P<relay_group_id>[^/].*)")  # noqa: E501

        def delete_callback(request):
            m = re.search(relay_group_delete_regex, request.url)

            relay_group_id = m.group('relay_group_id')
            relay_group_name = id2n(relay_group_id)

            if relay_group_name == "group_with_bundles":
                return (422, headers,
                        json.dumps({"errors":
                                    {"id":
                                     ["cannot delete relay group that "
                                      "has bundles assigned"]}}))
            elif relay_group_name == "group_with_members":
                return (422, headers,
                        json.dumps({"errors":
                                    {"id":
                                     ["cannot delete relay group that "
                                      "has relay members"]}}))
            else:
                return (204, headers, "")

        r.add_callback(responses.DELETE,
                       relay_group_delete_regex,
                       callback=delete_callback,
                       content_type="application/json")

        r.add(responses.GET,
              root + "/v1/bundles",
              json={'bundles': [
                  {"id": n2id("a_bundle"),
                   "name": "a_bundle",
                   "enabled_version": None},
                  {"id": n2id("another_bundle"),
                   "name": "another_bundle",
                   "enabled_version": None},
                  {"id": n2id("yet_another_bundle"),
                   "name": "yet_another_bundle",
                   "enabled_version": None}]},
              status=200)

        yield r

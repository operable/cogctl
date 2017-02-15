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

        r.add(responses.GET,
              root + "/v1/bundles",
              json={'bundles': [
                  {"id": "HAS_CONFIGS_ID",
                   "name": "has_configs"},
                  {"id": "NO_CONFIGS_ID",
                   "name": "no_configs"}
              ]})

        r.add(responses.GET,
              root + "/v1/bundles/HAS_CONFIGS_ID",
              json={'bundle': {
                  "enabled_version": None,
                  "id": "HAS_CONFIGS_ID",
                  "name": "has_configs"
              }},
              status=200)

        r.add(responses.GET,
              root + "/v1/bundles/NO_CONFIGS_ID",
              json={'bundle': {
                  "enabled_version": None,
                  "id": "NO_CONFIGS_ID",
                  "name": "no_configs"
              }},
              status=200)

        dynamic_config_regex = re.compile(
            "^.*/v1/bundles/HAS_CONFIGS_ID/dynamic_config/(?P<layer>.*)")

        def create_callback(request):
            m = dynamic_config_regex.search(request.url)

            raw_layer = m.group("layer")
            if raw_layer == "base":
                layer, name = ["base", "config"]
            else:
                layer, name = raw_layer.split("/", maxsplit=2)

            body = {"dynamic_configuration":
                    {"layer": layer,
                     "name": name,
                     "bundle_name": "has_configs"}}

            return (201,
                    {'content-type': 'application/json'},
                    json.dumps(body))

        r.add_callback(responses.POST,
                       dynamic_config_regex,
                       callback=create_callback,
                       content_type="application/json")

        r.add(responses.GET,
              root + "/v1/bundles/HAS_CONFIGS_ID/dynamic_config",
              json={"dynamic_configurations": [
                  {"layer": "base",
                   "name": "config",
                   "config": {
                       "config_1": "base_value_1",
                       "config_2": "base_value_2"
                   }},
                  {"layer": "room",
                   "name": "engineering",
                   "config": {
                       "config_1": "engineering_value_1",
                       "config_2": "engineering_value_2"
                   }},
                  {"layer": "user",
                   "name": "alice",
                   "config": {
                       "config_1": "alice_value_1",
                       "config_2": "alice_value_2"
                   }}
              ]},
              status=200)

        r.add(responses.GET,
              root + "/v1/bundles/NO_CONFIGS_ID/dynamic_config",
              json={"dynamic_configurations": []},
              status=200)

        r.add(responses.DELETE,
              dynamic_config_regex,
              status=204)

        yield r

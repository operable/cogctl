import pytest
from click.testing import CliRunner
from cogctl.cli.state import State
from functools import partial

import responses
import re
import json


@pytest.fixture
def cli_state():
    """Creates a CLI state object.
    """
    state = State()
    state.profile = {"url": "http://foo.bar.com:8080",
                     "user": "me",
                     "password": "seeeekrit"}
    return state


@pytest.fixture
def cogctl(cli_state):
    """Return a Click test runner preconfigured to run a cogctl command.

    """

    runner = CliRunner()
    with runner.isolated_filesystem():
        yield partial(runner.invoke,
                      obj=cli_state,
                      catch_exceptions=False)


@pytest.fixture
def mocks(cli_state):
    root = cli_state.profile["url"]

    def v2id(version):
        return ("BUNDLE_VERSION_ID_%s" % version)

    def id2v(id):
        return id.replace("BUNDLE_VERSION_ID_", "")

    with responses.RequestsMock(assert_all_requests_are_fired=False) as r:
        r.add(responses.POST,
              root + "/v1/token",
              json={"token": {"value": "abcdef0123456789"}},
              status=201)

        # A list of bundles
        # TODO: Some need invalid versions, too
        r.add(responses.GET,
              root + "/v1/bundles",
              json={'bundles': [
                  {"id": "ENABLED_BUNDLE_ID",
                   "name": "enabled_bundle",
                   "enabled_version": {"version": "0.0.2"},
                   "versions": [
                       {"version": "0.0.1"},
                       {"version": "0.0.2"},
                       {"version": "0.0.3"}
                   ]},
                  {"id": "DISABLED_BUNDLE_ID",
                   "name": "disabled_bundle",
                   "enabled_version": None,
                   "versions": [
                       {"version": "0.0.4"},
                       {"version": "0.0.5"},
                       {"version": "0.0.6"}
                   ]},
                  {"id": "HAS_INCOMPATIBLE_VERSIONS_ID",
                   "name": "has_incompatible_versions",
                   "enabled_version": {"version": "0.0.9"},
                   "versions": [
                       {"version": "0.0.9"}
                   ],
                   "incompatible_versions": [
                       {"version": "0.0.7"},
                       {"version": "0.0.8"}
                   ]}
              ]},
              status=200)

        r.add(responses.GET,
              root + "/v1/bundles/DISABLED_BUNDLE_ID",
              json={'bundle': {
                  "enabled_version": None,
                  "id": "DISABLED_BUNDLE_ID",
                  "name": "disabled_bundle",
                  "relay_groups": [],
                  "versions": [
                      {"version": "0.0.4",
                       "id": v2id("0.0.4")},
                      {"version": "0.0.5",
                       "id": v2id("0.0.5")},
                      {"version": "0.0.6",
                       "id": v2id("0.0.6")}
                  ]
              }},
              status=200)

        # Get an enabled version
        r.add(responses.GET,
              root + "/v1/bundles/ENABLED_BUNDLE_ID",
              json={'bundle': {
                  "enabled_version": {
                      "id": v2id("0.0.2"),
                      "version": "0.0.2",
                      "bundle_id": "ENABLED_BUNDLE_ID",
                      "name": "enabled_bundle",
                      "commands": [
                          {"name": "cmd1"},
                          {"name": "cmd2"},
                          {"name": "cmd3"}
                      ],
                      "permissions": [
                          {"bundle": "enabled_bundle", "name": "p1"},
                          {"bundle": "enabled_bundle", "name": "p2"},
                          {"bundle": "enabled_bundle", "name": "p3"}
                      ]
                  },
                  "id": "ENABLED_BUNDLE_ID",
                  "name": "enabled_bundle",
                  "relay_groups": [
                      {"name": "group1"},
                      {"name": "group2"},
                      {"name": "group3"}
                  ],
                  "versions": [
                      {"version": "0.0.1",
                       "id": v2id("0.0.1")},
                      {"version": "0.0.2",
                       "id": v2id("0.0.2")},
                      {"version": "0.0.3",
                       "id": v2id("0.0.3")}
                  ]
              }},
              status=200)

        r.add(responses.GET,
              root + "/v1/bundles/HAS_INCOMPATIBLE_VERSIONS_ID",
              json={'bundle': {
                  "enabled_version": {
                      "id": v2id("0.0.9"),
                      "version": "0.0.9",
                      "bundle_id": "HAS_INCOMPATIBLE_VERSIONS_ID",
                      "name": "has_incompatible_versions",
                      "commands": [
                          {"name": "cmd1"},
                          {"name": "cmd2"},
                          {"name": "cmd3"}
                      ],
                      "permissions": [
                          {"bundle": "enabled_bundle", "name": "p1"},
                          {"bundle": "enabled_bundle", "name": "p2"},
                          {"bundle": "enabled_bundle", "name": "p3"}
                      ]
                  },
                  "id": "HAS_INCOMPATIBLE_VERSIONS_ID",
                  "name": "has_incompatible_versions",
                  "relay_groups": [
                      {"name": "group1"},
                      {"name": "group2"},
                      {"name": "group3"}
                  ],
                  "versions": [
                      {"version": "0.0.9",
                       "id": v2id("0.0.9")}
                  ],
                  "incompatible_versions": [
                      {"version": "0.0.7",
                       "id": v2id("0.0.7")},
                      {"version": "0.0.8",
                       "id": v2id("0.0.8")}
                  ]
              }},
              status=200)

        r.add(responses.GET,
              root + "/v1/bundles/ENABLED_BUNDLE_ID/versions/",
              json={"bundle_versions":
                    [
                        {"id": v2id("0.0.1"),
                         "bundle_id": "ENABLED_BUNDLE_ID",
                         "name": "enabled_bundle",
                         "version": "0.0.1"},
                        {"id": v2id("0.0.2"),
                         "bundle_id": "ENABLED_BUNDLE_ID",
                         "name": "enabled_bundle",
                         "version": "0.0.2"},
                        {"id": v2id("0.0.3"),
                         "bundle_id": "ENABLED_BUNDLE_ID",
                         "name": "enabled_bundle",
                         "version": "0.0.3"}
                       ]},
              status=200)

        r.add(responses.GET,
              root + "/v1/bundles/DISABLED_BUNDLE_ID/versions/",
              json={"bundle_versions":
                    [
                        {"id": v2id("0.0.4"),
                         "bundle_id": "DISABLED_BUNDLE_ID",
                         "name": "disabled_bundle",
                         "version": "0.0.4"},
                        {"id": v2id("0.0.5"),
                         "bundle_id": "DISABLED_BUNDLE_ID",
                         "name": "disabled_bundle",
                         "version": "0.0.5"},
                        {"id": v2id("0.0.6"),
                         "bundle_id": "DISABLED_BUNDLE_ID",
                         "name": "disabled_bundle",
                         "version": "0.0.6"}
                    ]},
              status=200)

        r.add(responses.GET,
              root + "/v1/bundles/HAS_INCOMPATIBLE_VERSIONS_ID/versions/",
              json={"bundle_versions":
                    [
                        {"id": v2id("0.0.7"),
                         "bundle_id": "HAS_INCOMPATIBLE_VERSIONS_ID",
                         "name": "has_incompatible_versions",
                         "version": "0.0.7",
                         "incompatible": True},
                        {"id": v2id("0.0.8"),
                         "bundle_id": "HAS_INCOMPATIBLE_VERSIONS_ID",
                         "name": "has_incompatible_versions",
                         "version": "0.0.8",
                         "incompatible": True},
                        {"id": v2id("0.0.9"),
                         "bundle_id": "HAS_INCOMPATIBLE_VERSIONS_ID",
                         "name": "has_incompatible_versions",
                         "version": "0.0.9"}
                    ]},
              status=200)

        headers = {'content-type': 'application/json'}

        version_url_regex = re.compile("^.*/v1/bundles/(?P<bundle_id>[^/].*)/versions/(?P<version_id>[^/].*)")  # noqa: E501

        def version_callback(req):
            m = version_url_regex.search(req.url)
            bundle_id = m.group("bundle_id")
            version_id = m.group("version_id")

            if bundle_id == "ENABLED_BUNDLE_ID":
                bundle_name = "enabled_bundle"
            elif bundle_id == "DISABLED_BUNDLE_ID":
                bundle_name = "disabled_bundle"
            elif bundle_id == "HAS_INCOMPATIBLE_VERSIONS_ID":
                bundle_name = "has_incompatible_versions"

            else:  # pragma: nocover
                raise Exception("Unrecognized mock bundle ID: %s" % bundle_id)

            version = id2v(version_id)

            enabled = (bundle_name == "enabled_bundle" and
                       version == "0.0.2")  # TODO: make a variable for this

            body = {'bundle_version': {
                "bundle_id": bundle_id,
                "id": version_id,
                "name": bundle_name,
                "enabled": enabled,
                "version": version,
                "commands": [
                    {"name": "cmd1"},
                    {"name": "cmd2"},
                    {"name": "cmd3"}
                ],
                "permissions": [
                    {"bundle": bundle_name, "name": "p1"},
                    {"bundle": bundle_name, "name": "p2"},
                    {"bundle": bundle_name, "name": "p3"}
                ]
            }}

            return (200, headers, json.dumps(body))

        r.add_callback(responses.GET,
                       version_url_regex,
                       callback=version_callback,
                       content_type='application/json')

        r.add(responses.DELETE,
              version_url_regex,
              status=204)

        version_status_regex = re.compile("^.*/v1/bundles/(?P<bundle_id>[^/].*)/versions/(?P<version_id>[^/].*)/status")  # noqa: E501

        def status_callback(req):
            payload = json.loads(req.body.decode())

            m = version_status_regex.search(req.url)
            bundle_id = m.group("bundle_id")
            version_id = m.group("version_id")

            if bundle_id == "ENABLED_BUNDLE_ID":
                bundle_name = "enabled_bundle"
            elif bundle_id == "DISABLED_BUNDLE_ID":
                bundle_name = "disabled_bundle"

            # TODO: create a "standard registry bundle" for use here
            elif bundle_id == "twitter_ID":
                bundle_name = "twitter"

            else:  # pragma: nocover
                raise Exception(
                    "Unrecognized mock bundle ID: {}".format(bundle_id))

            version = id2v(version_id)

            if payload['status'] == 'enabled':
                resp_body = {'enabled_version': version,
                             'name': bundle_name,
                             'enabled': True,
                             'relays': []}
            else:
                resp_body = {'name': bundle_name,
                             'enabled': False,
                             'relays': []}

            return (200, headers, json.dumps(resp_body))

        r.add_callback(responses.POST,
                       version_status_regex,
                       callback=status_callback,
                       content_type="application/json")

        def install_callback(request):
            payload = json.loads(request.body.decode())
            bundle_name = payload['bundle']['config']['name']
            force = payload['bundle']['force']
            version = payload['bundle']['config']['version']

            # 2.0.0 == already installed
            if (version == "2.0.0" and not force):
                body = {"errors": ["Could not save bundle.",
                                   "version has already been taken"]}
                return (409, headers, json.dumps(body))

            if (version == "2.0.0" and force):
                body = {"bundle_version":
                        {"id": "%s_VERSION_ID" % bundle_name,
                         "bundle_id": "%s_ID" % bundle_name,
                         "name": bundle_name,
                         "version": version}}
                return (201, headers, json.dumps(body))

            body = {"bundle_version":
                    {"id": "%s_VERSION_ID" % bundle_name,
                     "bundle_id": "%s_ID" % bundle_name,
                     "name": bundle_name,
                     "version": version}}
            return (201, headers, json.dumps(body))

        r.add_callback(responses.POST,
                       root + "/v1/bundles",
                       callback=install_callback,
                       content_type="application/json")

        registry_regex = re.compile("^.*/v1/bundles/install/(?P<bundle>[^/].*)/(?P<version>[^/].*)$")  # noqa: E501

        def registry_callback(request):
            m = re.search(registry_regex, request.url)
            bundle_name = m.group('bundle')
            version = m.group('version')

            if version == "6.6.6":
                # "6.6.6" is the Version of the Beast
                body = {"errors":
                        ["Bundle \"%s\" version \"6.6.6\" not found." % bundle_name]}  # noqa: E501
                return (404, headers, json.dumps(body))

            if version == "2.0.0":
                # We'll say this version already exists
                body = {"errors": ["Could not save bundle.",
                                   "version has already been taken"]}
                return (409, headers, json.dumps(body))

            else:
                body = {"bundle_version":
                        {"id": "%s_VERSION_ID" % bundle_name,
                         "bundle_id": "%s_ID" % bundle_name,
                         "name": bundle_name,
                         "version": "10.0.0" if version == "latest" else version}}  # noqa: E501
                return (201, headers, json.dumps(body))

        r.add_callback(responses.POST,
                       registry_regex,
                       callback=registry_callback,
                       content_type="application/json")

        def rg2id(name):
            return "%s_id" % name

        def id2rg(id):
            return id.replace("_id", "")

        r.add(responses.GET,
              root + "/v1/relay_groups",
              json={"relay_groups":
                    [{"id": rg2id("group_1"),
                      "name": "group_1"},
                     {"id": rg2id("group_2"),
                      "name": "group_2"},
                     {"id": rg2id("group_3"),
                      "name": "group_3"}]},
              status=200)

        relay_group_assign_regex = re.compile("^.*/v1/relay_groups/(?P<relay_group_id>[^/].*)/bundles")  # noqa: E501

        def relay_group_assign_callback(request):
            m = re.search(relay_group_assign_regex, request.url)
            relay_group_id = m.group('relay_group_id')

            relay_group_name = id2rg(relay_group_id)

            body = {"relay_group":
                    {"id": relay_group_id,
                     "name": relay_group_name,
                     "relays": [],
                     "bundles": [
                         # TODO: add bundle name

                     ]}}
            return (200, headers, json.dumps(body))

        r.add_callback(responses.POST,
                       relay_group_assign_regex,
                       callback=relay_group_assign_callback,
                       content_type="application/json")

        yield r

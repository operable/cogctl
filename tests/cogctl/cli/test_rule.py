import pytest
from cogctl.cli import rule
import responses


@pytest.fixture(autouse=True)
def mocks(request, cli_state):
    with responses.RequestsMock(assert_all_requests_are_fired=False) as rsps:
        base_url = "%s/v1" % cli_state.profile["url"]
        rule_id = "b5fb5598-e133-46ad-9ada-4788b00277ad"

        # Token
        rsps.add(responses.POST,
                 "%s/token" % base_url,
                 json={"token": {"value": "lolwut"}},
                 status=200)

        # Rules Index
        rsps.add(responses.GET,
                 "%s/rules" % base_url,
                 json={"rules": [{"id": "c3f708a4-2d2f-4b15-b78a-c800a191a9b9",
                                  "command": "ec2:instance-list",
                                  "rule": "when command is ec2:instance-list must have ec2:read"}]}, # noqa
                 status=200)

        # Rules Show
        rsps.add(responses.GET,
                 "%s/rules/%s" % (base_url, rule_id),
                 json={"id": "b5fb5598-e133-46ad-9ada-4788b00277ad",
                       "rule": "when command is ec2:instance-create with option[\"region\"] == \"us-east-1\" must have site:east-admin", # noqa
                       "command": "ec2:instance-create"},
                 status=200)

        # Rules Create
        rsps.add(responses.POST,
                 "%s/rules" % base_url,
                 json={"id": "b5fb5598-e133-46ad-9ada-4788b00277ad",
                       "rule": "when command is ec2:instance-create with option[\"region\"] == \"us-east-1\" must have site:east-admin", # noqa
                       "command": "ec2:instance-create"},
                 status=201)

        # Rules Delete
        rsps.add(responses.DELETE,
                 "%s/rules/%s" % (base_url, rule_id),
                 json={"id": "b5fb5598-e133-46ad-9ada-4788b00277ad",
                       "rule": "when command is ec2:instance-create with option[\"region\"] == \"us-east-1\" must have site:east-admin", # noqa
                       "command": "ec2:instance-create"},
                 status=204)

        # Bundles Index
        rsps.add(responses.GET,
                 "%s/bundles" % base_url,
                 json={"bundles":
                         [{"name": "ec2", # noqa
                           "enabled_version":
                               {"commands": [{
                                   "name": "instance-list",
                                   "bundle": "ec2"}]}}]},
                 status=200)

        yield rsps


def test_rule_list(cogctl):
    result = cogctl(rule.list_rules, ["ec2:instance-list"])

    assert result.exit_code == 0
    assert result.output == """\
ID                                    RULE
c3f708a4-2d2f-4b15-b78a-c800a191a9b9  when command is ec2:instance-list must have ec2:read
""" # noqa


def test_rule_list_for_missing_command(cogctl):
    result = cogctl(rule.list_rules, ["ec2:lolwtfbbq"])

    assert not result.exit_code == 0
    assert "Error: Invalid value for \"command\": Command \"ec2:lolwtfbbq\" was not found" # noqa


def test_rule_create(cogctl):
    result = cogctl(rule.create,
                    ["when command is ec2:instance-create with option[\"region\"] == \"us-east-1\" must have site:east-admin"]) # noqa

    assert result.exit_code == 0
    assert result.output == """\
ID    b5fb5598-e133-46ad-9ada-4788b00277ad
Rule  when command is ec2:instance-create with option["region"] == "us-east-1" must have site:east-admin
""" # noqa


def test_rule_delete(cogctl):
    result = cogctl(rule.delete, ["b5fb5598-e133-46ad-9ada-4788b00277ad"])

    assert result.exit_code == 0
    assert result.output == ""

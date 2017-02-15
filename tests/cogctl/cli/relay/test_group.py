import pytest
import cogctl.cli.relay.group as relay_group


pytestmark = pytest.mark.usefixtures("mocks")


# create
########################################################################


def test_group_creation_without_relays(cogctl):
    result = cogctl(relay_group.create, ["new_group"])

    assert result.exit_code == 0
    assert result.output == """\
Created relay group 'new_group'
"""


def test_group_creation_with_existing_group_name(cogctl):
    result = cogctl(relay_group.create, ["group_1"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: create [OPTIONS] NAME [RELAYS]...

Error: Invalid value for "name": A relay group named 'group_1' already exists.
"""


def test_group_creation_with_one_relay(cogctl):
    result = cogctl(relay_group.create, ["new_group", "relay_1"])

    assert result.exit_code == 0
    assert result.output == """\
Created relay group 'new_group'
Relay group 'new_group' has the following relay members: relay_1
"""


def test_group_creation_with_multiple_relays(cogctl):
    result = cogctl(relay_group.create, ["new_group",
                                         "relay_1", "relay_3", "relay_2"])

    assert result.exit_code == 0
    assert result.output == """\
Created relay group 'new_group'
Relay group 'new_group' has the following relay members: relay_1, relay_2, relay_3
"""  # noqa: E501


def test_group_creation_with_nonexistent_relays(cogctl):
    result = cogctl(relay_group.create, ["new_group",
                                         "relay_1", "not_a_relay", "nope"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: create [OPTIONS] NAME [RELAYS]...

Error: Invalid value for "relays": The following relays do not exist: nope, not_a_relay
"""  # noqa: E501


# delete
########################################################################


def test_delete_single_group(cogctl):
    result = cogctl(relay_group.delete, ["group_1"])

    assert result.exit_code == 0
    assert result.output == """\
Deleted relay group 'group_1'
"""


def test_delete_multiple_groups(cogctl):
    result = cogctl(relay_group.delete, ["group_1", "group_2", "group_3"])

    assert result.exit_code == 0
    assert result.output == """\
Deleted relay group 'group_1'
Deleted relay group 'group_2'
Deleted relay group 'group_3'
"""


def test_delete_nonexistent_group(cogctl):
    result = cogctl(relay_group.delete, ["group_1", "not_a_group", "group_3"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: delete [OPTIONS] GROUPS...

Error: Invalid value for "groups": The following relay groups do not exist: not_a_group
"""  # noqa: E501


def test_delete_group_with_assigned_bundles(cogctl):
    result = cogctl(relay_group.delete, ["group_with_bundles"])

    assert result.exit_code == 1
    assert result.output == """\
Error: cannot delete relay group that has bundles assigned
"""


def test_delete_group_with_members(cogctl):
    result = cogctl(relay_group.delete, ["group_with_members"])

    assert result.exit_code == 1
    assert result.output == """\
Error: cannot delete relay group that has relay members
"""


def test_delete_with_no_groups(cogctl):
    result = cogctl(relay_group.delete, [])

    assert result.exit_code == 2
    assert result.output == """\
Usage: delete [OPTIONS] GROUPS...

Error: Missing argument "groups".
"""


# add
########################################################################


def test_add_single_relay_to_empty_group(cogctl):
    result = cogctl(relay_group.add, ["group_1", "relay_1"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_1' has the following relay members: relay_1
"""


def test_add_multiple_relays_to_empty_group(cogctl):
    result = cogctl(relay_group.add, ["group_1",
                                      "relay_1", "relay_2", "relay_3"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_1' has the following relay members: relay_1, relay_2, relay_3
"""  # noqa: E501


def test_add_single_relay_to_group_with_relays(cogctl):
    result = cogctl(relay_group.add, ["group_with_members", "relay_1"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_with_members' has the following relay members: a_relay, another_relay, relay_1
"""  # noqa: E501


def test_add_multiple_relays_to_group_with_relays(cogctl):
    result = cogctl(relay_group.add, ["group_with_members",
                                      "relay_1", "relay_2", "relay_3"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_with_members' has the following relay members: a_relay, another_relay, relay_1, relay_2, relay_3
"""  # noqa: E501


def test_add_to_nonexistent_group(cogctl):
    result = cogctl(relay_group.add, ["not_a_group",
                                      "relay_1", "relay_2", "relay_3"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: add [OPTIONS] GROUP RELAYS...

Error: Invalid value for "group": The relay group 'not_a_group' does not exist
"""


def test_add_nonexistent_relay_to_group(cogctl):
    result = cogctl(relay_group.add, ["group_with_members",
                                      "relay_1", "not_a_relay",
                                      "nope_still_not_a_relay"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: add [OPTIONS] GROUP RELAYS...

Error: Invalid value for "relays": The following relays do not exist: nope_still_not_a_relay, not_a_relay
"""  # noqa: E501


def test_add_no_relays_to_groups(cogctl):
    result = cogctl(relay_group.add, ["group_with_members"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: add [OPTIONS] GROUP RELAYS...

Error: Missing argument "relays".
"""


# remove
########################################################################


def test_remove_single_relay_from_group(cogctl):
    result = cogctl(relay_group.remove, ["group_with_members", "a_relay"])

#    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_with_members' has the following relay members: another_relay
"""


def test_remove_multiple_relays_from_group(cogctl):
    result = cogctl(relay_group.remove, ["group_with_members",
                                         "a_relay", "another_relay"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_with_members' has no relay members.
"""


def test_remove_relay_from_group_it_is_not_in(cogctl):
    result = cogctl(relay_group.remove, ["group_1", "relay_1"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: remove [OPTIONS] GROUP [RELAYS]...

Error: Invalid value for "relays": The following relays are not members of the group 'group_1': relay_1
"""  # noqa: E501


def test_remove_from_nonexistent_group(cogctl):
    result = cogctl(relay_group.remove, ["not_a_group", "relay_1"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: remove [OPTIONS] GROUP [RELAYS]...

Error: Invalid value for "group": The relay group 'not_a_group' does not exist
"""


def test_remove_with_no_relays_or_all_option(cogctl):
    result = cogctl(relay_group.remove, ["group_1"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: remove [OPTIONS] GROUP [RELAYS]...

Error: Invalid value: You must provide either relay names, or specify the '--all' option
"""  # noqa: E501


def test_remove_with_relays_and_all_option(cogctl):
    result = cogctl(relay_group.remove, ["group_with_members",
                                         "a_relay", "another_relay",
                                         "--all"])
    assert result.exit_code == 2
    assert result.output == """\
Usage: remove [OPTIONS] GROUP [RELAYS]...

Error: Invalid value: You cannot provide both relay names and the '--all' option
"""  # noqa: E501


def test_remove_with_all_option(cogctl):
    result = cogctl(relay_group.remove, ["group_with_members", "--all"])

    assert result.exit_code == 0
    assert result.output == """\
Warning: Removing ALL relays from group 'group_with_members': a_relay, another_relay
Relay group 'group_with_members' has no relay members.
"""  # noqa: E501


# assign
########################################################################


def test_assign_single_bundle_to_unassigned_group(cogctl):
    result = cogctl(relay_group.assign, ["group_1", "a_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_1' has the following assigned bundles: a_bundle
"""


def test_assign_multiple_bundles_to_unassigned_group(cogctl):
    result = cogctl(relay_group.assign, ["group_1",
                                         "a_bundle", "another_bundle",
                                         "yet_another_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_1' has the following assigned bundles: a_bundle, another_bundle, yet_another_bundle
"""  # noqa: E501


def test_assign_single_bundle_to_group_with_bundles(cogctl):
    result = cogctl(relay_group.assign, ["group_with_bundles",
                                         "another_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_with_bundles' has the following assigned bundles: a_bundle, another_bundle, bundle_1
"""  # noqa: E501


def test_assign_multiple_bundles_to_group_with_bundles(cogctl):
    result = cogctl(relay_group.assign, ["group_with_bundles",
                                         "another_bundle",
                                         "yet_another_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_with_bundles' has the following assigned bundles: a_bundle, another_bundle, bundle_1, yet_another_bundle
"""  # noqa: E501


def test_assign_to_nonexistent_group(cogctl):
    result = cogctl(relay_group.assign, ["not_a_group", "a_bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: assign [OPTIONS] GROUP BUNDLES...

Error: Invalid value for "group": The relay group 'not_a_group' does not exist
"""


def test_assign_nonexistent_bundle_to_group(cogctl):
    result = cogctl(relay_group.assign, ["group_1",
                                         "not_a_bundle", "a_bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: assign [OPTIONS] GROUP BUNDLES...

Error: Invalid value for "bundles": The following bundles do not exist: not_a_bundle
"""  # noqa: E501


def test_assign_no_bundles_to_group(cogctl):
    result = cogctl(relay_group.assign, ["group_1"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: assign [OPTIONS] GROUP BUNDLES...

Error: Missing argument "bundles".
"""


# unassign
########################################################################


def test_unassign_single_bundle_from_group(cogctl):
    result = cogctl(relay_group.unassign, ["group_with_bundles", "a_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_with_bundles' has the following assigned bundles: bundle_1
"""


def test_unassign_multiple_bundles_from_group(cogctl):
    result = cogctl(relay_group.unassign, ["group_with_bundles",
                                           "a_bundle", "bundle_1"])

    assert result.exit_code == 0
    assert result.output == """\
Relay group 'group_with_bundles' has no assigned bundles.
"""


def test_unassign_single_bundle_from_group_it_is_not_assigned_to(cogctl):
    result = cogctl(relay_group.unassign, ["group_1", "a_bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: unassign [OPTIONS] GROUP [BUNDLES]...

Error: Invalid value for "bundles": The following bundles are not assigned to the group 'group_1': a_bundle
"""  # noqa: E501


def test_unassign_from_nonexistent_group(cogctl):
    result = cogctl(relay_group.unassign, ["not_a_group", "a_bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: unassign [OPTIONS] GROUP [BUNDLES]...

Error: Invalid value for "group": The relay group 'not_a_group' does not exist
"""


def test_unassign_nonexistent_bundle_from_group(cogctl):
    result = cogctl(relay_group.unassign, ["group_with_bundles",
                                           "not_a_bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: unassign [OPTIONS] GROUP [BUNDLES]...

Error: Invalid value for "bundles": The following bundles are not assigned to the group 'group_with_bundles': not_a_bundle
"""  # noqa: E501


def test_unassign_no_bundles_and_no_all_option(cogctl):
    result = cogctl(relay_group.unassign, ["group_with_bundles"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: unassign [OPTIONS] GROUP [BUNDLES]...

Error: Invalid value: You must provide either bundle names, or specify the '--all' option
"""  # noqa: E501


def test_unassign_with_bundles_and_all_option(cogctl):
    result = cogctl(relay_group.unassign, ["group_with_bundles",
                                           "a_bundle", "bundle_1",
                                           "--all"])
    assert result.exit_code == 2
    assert result.output == """\
Usage: unassign [OPTIONS] GROUP [BUNDLES]...

Error: Invalid value: You cannot provide both bundle names and the '--all' option
"""  # noqa: E501


def test_unassign_with_all_option(cogctl):
    result = cogctl(relay_group.unassign, ["group_with_bundles", "--all"])

    assert result.exit_code == 0
    assert result.output == """\
Warning: Unassigning ALL bundles from group 'group_with_bundles': a_bundle, bundle_1
Relay group 'group_with_bundles' has no assigned bundles.
"""  # noqa: E501


# info
########################################################################


def test_info(cogctl):
    result = cogctl(relay_group.info, ["group_with_bundles_and_relays"])

    assert result.exit_code == 0
    assert result.output == """\
Name           group_with_bundles_and_relays
ID             group_with_bundles_and_relays_id
Creation Time  1970-01-01T00:00:05

Relays
NAME           ID
a_relay        a_relay_id
another_relay  another_relay_id

Bundles
NAME      ID
a_bundle  a_bundle_id
bundle_1  bundle_1_id
"""


def test_info_for_nonexistent_group(cogctl):
    result = cogctl(relay_group.info, ["not_a_group"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: info [OPTIONS] GROUP

Error: Invalid value for "group": The relay group 'not_a_group' does not exist
"""


# list (default)
########################################################################

def test_list(cogctl):
    result = cogctl(relay_group.relay_group, [])

    assert result.exit_code == 0
    assert result.output == """\
NAME                           INSERTED AT          ID
group_1                        1970-01-01T00:00:00  group_1_id
group_2                        1970-01-01T00:00:01  group_2_id
group_3                        1970-01-01T00:00:02  group_3_id
group_with_bundles             1970-01-01T00:00:03  group_with_bundles_id
group_with_bundles_and_relays  1970-01-01T00:00:05  group_with_bundles_and_relays_id
group_with_members             1970-01-01T00:00:04  group_with_members_id
"""  # noqa: E501

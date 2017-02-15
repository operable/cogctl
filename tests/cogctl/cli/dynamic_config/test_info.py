import pytest
import cogctl.cli.bundle.config as bundle_config


pytestmark = pytest.mark.usefixtures("mocks")


def test_info_for_base_layer(cogctl):
    result = cogctl(bundle_config.info, ["has_configs",
                                         "base"])

    assert result.exit_code == 0
    assert result.output == """\
"config_1": "base_value_1"
"config_2": "base_value_2"
"""


def test_info_for_room_layer(cogctl):
    result = cogctl(bundle_config.info, ["has_configs",
                                         "room/engineering"])

    assert result.exit_code == 0
    assert result.output == """\
"config_1": "engineering_value_1"
"config_2": "engineering_value_2"
"""


def test_info_for_user_layer(cogctl):
    result = cogctl(bundle_config.info, ["has_configs",
                                         "user/alice"])

    assert result.exit_code == 0
    assert result.output == """\
"config_1": "alice_value_1"
"config_2": "alice_value_2"
"""


def test_info_for_invalid_layer(cogctl):
    result = cogctl(bundle_config.info, ["has_configs",
                                         "not/really-a/layer"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: info [OPTIONS] BUNDLE_NAME [LAYER]

Error: Invalid value for "layer": Must specify layer as 'base', 'room/$NAME', or 'user/$NAME'
"""  # noqa: E501


def test_info_for_nonexistent_layer(cogctl):
    result = cogctl(bundle_config.info, ["has_configs",
                                         "room/not-a-room"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: info [OPTIONS] BUNDLE_NAME [LAYER]

Error: Invalid value for "layer": Layer 'room/not-a-room' not found for bundle 'has_configs'
"""  # noqa: E501


def test_info_for_nonexistent_bundle(cogctl):
    result = cogctl(bundle_config.info, ["not-a-bundle",
                                         "base"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: info [OPTIONS] BUNDLE_NAME [LAYER]

Error: Invalid value for "name": Bundle 'not-a-bundle' not found
"""

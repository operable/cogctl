import pytest
import cogctl.cli.bundle.config as bundle_config


pytestmark = pytest.mark.usefixtures("mocks")


def test_delete_base_config(cogctl):
    result = cogctl(bundle_config.delete, ["has_configs", "base"])

    assert result.exit_code == 0
    assert result.output == """\
Deleted 'base' layer for bundle 'has_configs'
"""


def test_delete_room_config(cogctl):
    result = cogctl(bundle_config.delete, ["has_configs",
                                           "room/engineering"])

    assert result.exit_code == 0
    assert result.output == """\
Deleted 'room/engineering' layer for bundle 'has_configs'
"""


def test_delete_user_config(cogctl):
    result = cogctl(bundle_config.delete, ["has_configs",
                                           "user/alice"])

    assert result.exit_code == 0
    assert result.output == """\
Deleted 'user/alice' layer for bundle 'has_configs'
"""


def test_delete_invalid_layer(cogctl):
    result = cogctl(bundle_config.delete, ["has_configs",
                                           "lolwut/not/a/layer"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: delete [OPTIONS] BUNDLE_NAME [LAYER]

Error: Invalid value for "layer": Must specify layer as 'base', 'room/$NAME', or 'user/$NAME'
"""  # noqa: E501


def test_delete_nonexistent_layer(cogctl):
    result = cogctl(bundle_config.delete, ["has_configs", "room/no_layer"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: delete [OPTIONS] BUNDLE_NAME [LAYER]

Error: Invalid value for "layer": Layer 'room/no_layer' not found for bundle 'has_configs'
"""  # noqa: E501


def test_delete_layer_from_nonexistent_bundle(cogctl):
    result = cogctl(bundle_config.delete, ["not_a_bundle", "base"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: delete [OPTIONS] BUNDLE_NAME [LAYER]

Error: Invalid value for "name": Bundle 'not_a_bundle' not found
"""

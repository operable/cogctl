import pytest
import cogctl.cli.bundle.config as bundle_config


pytestmark = pytest.mark.usefixtures("mocks")


def test_layers_for_bundle_with_layers(cogctl):
    result = cogctl(bundle_config.layers, ["has_configs"])

    assert result.exit_code == 0
    assert result.output == """\
base
room/engineering
user/alice
"""


def test_layers_for_bundle_without_layers(cogctl):
    result = cogctl(bundle_config.layers, ["no_configs"])

    assert result.exit_code == 0
    assert result.output == """\
No dynamic configuration layers for no_configs
"""


def test_layers_for_nonexistent_bundle(cogctl):
    result = cogctl(bundle_config.layers, ["not-a-bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: layers [OPTIONS] BUNDLE_NAME

Error: Invalid value for "name": Bundle 'not-a-bundle' not found
"""

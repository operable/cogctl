import pytest
import cogctl.cli.bundle.disable as bundle  # TODO: Eww, this import


pytestmark = pytest.mark.usefixtures("mocks")


def test_disable_enabled_bundle(cogctl):
    result = cogctl(bundle.disable, ["enabled_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
Disabled enabled_bundle
"""


def test_disable_nonexistent_bundle(cogctl):
    result = cogctl(bundle.disable, ["not_a_bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: disable [OPTIONS] NAME

Error: Invalid value for "name": Bundle 'not_a_bundle' not found
"""


def test_disable_disabled_bundle(cogctl):
    result = cogctl(bundle.disable, ["disabled_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
disabled_bundle was already disabled
"""

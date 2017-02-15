import pytest
import cogctl.cli.bundle.enable as bundle  # TODO: Eww, this import


pytestmark = pytest.mark.usefixtures("mocks")


# TODO: What happens when you try to enable a bundle that's already enabled?


def test_enable_no_version_enables_latest(cogctl):
    result = cogctl(bundle.enable, ["disabled_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
Enabled disabled_bundle 0.0.6
"""


def test_enable_with_version(cogctl):
    result = cogctl(bundle.enable, ["disabled_bundle", "0.0.4"])

    assert result.exit_code == 0
    assert result.output == """\
Enabled disabled_bundle 0.0.4
"""


def test_enable_nonexistent_version(cogctl):
    result = cogctl(bundle.enable, ["enabled_bundle", "100.0.0"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: enable [OPTIONS] NAME [VERSION]

Error: Invalid value for "version": No version 100.0.0 found for enabled_bundle
"""


def test_enable_nonexistent_bundle(cogctl):
    result = cogctl(bundle.enable, ["not_a_bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: enable [OPTIONS] NAME [VERSION]

Error: Invalid value for "name": Bundle 'not_a_bundle' not found
"""


def test_enable_invalid_version(cogctl):
    result = cogctl(bundle.enable, ["enabled_bundle", "not_a_version"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: enable [OPTIONS] NAME [VERSION]

Error: Invalid value for "version": Versions must be of the form 'major.minor.patch'
"""  # noqa: E501

import pytest
import cogctl.cli.bundle.info as bundle  # TODO: Eww, this import


pytestmark = pytest.mark.usefixtures("mocks")


def test_info_bundle_not_found(cogctl):
    result = cogctl(bundle.info, ["not_a_bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: info [OPTIONS] NAME [VERSION]

Error: Invalid value for "name": Bundle 'not_a_bundle' not found
"""


def test_info_enabled(cogctl):
    result = cogctl(bundle.info, ["enabled_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
Bundle ID:        ENABLED_BUNDLE_ID
Version ID:       BUNDLE_VERSION_ID_0.0.2
Name:             enabled_bundle
Versions:         0.0.1, 0.0.2, 0.0.3
Status:           Enabled
Enabled Version:  0.0.2
Commands:         cmd1, cmd2, cmd3
Permissions:      enabled_bundle:p1, enabled_bundle:p2, enabled_bundle:p3
Relay Groups:     group1, group2, group3
"""


def test_info_disabled(cogctl):
    result = cogctl(bundle.info, ["disabled_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
Bundle ID:  DISABLED_BUNDLE_ID
Name:       disabled_bundle
Versions:   0.0.4, 0.0.5, 0.0.6
Status:     Disabled
"""


def test_info_specific_version(cogctl):
    result = cogctl(bundle.info, ["enabled_bundle", "0.0.1"])

    assert result.exit_code == 0
    assert result.output == """\
Bundle ID:    ENABLED_BUNDLE_ID
Version Id:   BUNDLE_VERSION_ID_0.0.1
Name:         enabled_bundle
Status:       Disabled
Version:      0.0.1
Commands:     cmd1, cmd2, cmd3
Permissions:  enabled_bundle:p1, enabled_bundle:p2, enabled_bundle:p3
"""


def test_info_specific_version_not_found(cogctl):
    result = cogctl(bundle.info, ["enabled_bundle", "100.0.0"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: info [OPTIONS] NAME [VERSION]

Error: Invalid value for "version": No version 100.0.0 found for enabled_bundle
"""


def test_info_version_must_be_valid(cogctl):
    result = cogctl(bundle.info, ["enabled_bundle", "not_a_version"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: info [OPTIONS] NAME [VERSION]

Error: Invalid value for "version": Versions must be of the form 'major.minor.patch'
"""  # noqa: E501

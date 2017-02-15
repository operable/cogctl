import pytest
import cogctl.cli.bundle.versions as bundle  # TODO: Eww, this import


pytestmark = pytest.mark.usefixtures("mocks")


def test_versions_with_no_args_lists_everything(cogctl):
    result = cogctl(bundle.versions, [])

    assert result.exit_code == 0
    assert result.output == """\
BUNDLE                     VERSION  STATUS
disabled_bundle            0.0.4    Disabled
disabled_bundle            0.0.5    Disabled
disabled_bundle            0.0.6    Disabled
enabled_bundle             0.0.1    Disabled
enabled_bundle             0.0.2    Enabled
enabled_bundle             0.0.3    Disabled
has_incompatible_versions  0.0.7    Incompatible
has_incompatible_versions  0.0.8    Incompatible
has_incompatible_versions  0.0.9    Enabled
"""


def test_versions_list_all_incompatible_versions(cogctl):
    result = cogctl(bundle.versions, ["--incompatible"])

    assert result.exit_code == 0
    assert result.output == """\
BUNDLE                     VERSION  STATUS
has_incompatible_versions  0.0.7    Incompatible
has_incompatible_versions  0.0.8    Incompatible
"""


def test_versions_for_specific_bundle(cogctl):
    result = cogctl(bundle.versions, ["enabled_bundle"])

    assert result.exit_code == 0
    assert result.output == """\
BUNDLE          VERSION  STATUS
enabled_bundle  0.0.1    Disabled
enabled_bundle  0.0.2    Enabled
enabled_bundle  0.0.3    Disabled
"""


def test_versions_list_incompatible_for_bundle_with_no_incompatible_versions(cogctl):  # noqa: E501
    result = cogctl(bundle.versions, ["enabled_bundle", "--incompatible"])

    assert result.exit_code == 0
    assert result.output == """\
BUNDLE  VERSION  STATUS
"""


def test_versions_list_incompatible_for_bundle_with_incompatible_versions(cogctl):  # noqa: E501
    result = cogctl(bundle.versions, ["has_incompatible_versions",
                                      "--incompatible"])

    assert result.exit_code == 0
    assert result.output == """\
BUNDLE                     VERSION  STATUS
has_incompatible_versions  0.0.7    Incompatible
has_incompatible_versions  0.0.8    Incompatible
"""


def test_versions_for_nonexistent_bundle(cogctl):
    result = cogctl(bundle.versions, ["not_a_bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: versions [OPTIONS] NAME

Error: Invalid value for "name": Bundle 'not_a_bundle' not found
"""

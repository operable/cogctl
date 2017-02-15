import pytest
from cogctl.cli.bundle.main import bundle  # TODO: Eww, this import


pytestmark = pytest.mark.usefixtures("mocks")


def test_bundle_list(cogctl):
    result = cogctl(bundle, [])

    assert result.exit_code == 0
    assert result.output == """\
NAME                       ENABLED VERSION
disabled_bundle            (disabled)
enabled_bundle             0.0.2
has_incompatible_versions  0.0.9
"""


def test_bundle_list_verbose(cogctl):
    result = cogctl(bundle, ["--verbose"])

    assert result.exit_code == 0
    assert result.output == """\
NAME                       ENABLED VERSION  INSTALLED VERSIONS   BUNDLE ID
disabled_bundle            (disabled)       0.0.4, 0.0.5, 0.0.6  DISABLED_BUNDLE_ID
enabled_bundle             0.0.2            0.0.1, 0.0.2, 0.0.3  ENABLED_BUNDLE_ID
has_incompatible_versions  0.0.9            0.0.9                HAS_INCOMPATIBLE_VERSIONS_ID
"""  # noqa: E501


def test_bundle_list_only_enabled_bundles(cogctl):
    result = cogctl(bundle, ["--enabled"])

    assert result.exit_code == 0
    assert result.output == """\
NAME                       ENABLED VERSION
enabled_bundle             0.0.2
has_incompatible_versions  0.0.9
"""


def test_bundle_list_enabled_verbose(cogctl):
    result = cogctl(bundle, ["--enabled", "--verbose"])

    assert result.exit_code == 0
    assert result.output == """\
NAME                       ENABLED VERSION  INSTALLED VERSIONS   BUNDLE ID
enabled_bundle             0.0.2            0.0.1, 0.0.2, 0.0.3  ENABLED_BUNDLE_ID
has_incompatible_versions  0.0.9            0.0.9                HAS_INCOMPATIBLE_VERSIONS_ID
"""  # noqa: E501


def test_bundle_list_only_disabled_bundles(cogctl):
    result = cogctl(bundle, ["--disabled"])

    assert result.exit_code == 0
    assert result.output == """\
NAME             ENABLED VERSION
disabled_bundle  (disabled)
"""


def test_bundle_list_disabled_verbose(cogctl):
    result = cogctl(bundle, ["--disabled", "--verbose"])

    assert result.exit_code == 0
    assert result.output == """\
NAME             ENABLED VERSION  INSTALLED VERSIONS   BUNDLE ID
disabled_bundle  (disabled)       0.0.4, 0.0.5, 0.0.6  DISABLED_BUNDLE_ID
"""


def test_bundle_list_can_specify_disabled_and_enabled(cogctl):
    result = cogctl(bundle, ["--disabled", "--enabled"])

    assert result.exit_code == 0
    assert result.output == """\
NAME                       ENABLED VERSION
disabled_bundle            (disabled)
enabled_bundle             0.0.2
has_incompatible_versions  0.0.9
"""


def test_bundle_list_enabled_and_disabled_verbose(cogctl):
    result = cogctl(bundle, ["--enabled", "--disabled", "--verbose"])

    assert result.exit_code == 0
    assert result.output == """\
NAME                       ENABLED VERSION  INSTALLED VERSIONS   BUNDLE ID
disabled_bundle            (disabled)       0.0.4, 0.0.5, 0.0.6  DISABLED_BUNDLE_ID
enabled_bundle             0.0.2            0.0.1, 0.0.2, 0.0.3  ENABLED_BUNDLE_ID
has_incompatible_versions  0.0.9            0.0.9                HAS_INCOMPATIBLE_VERSIONS_ID
"""  # noqa: E501

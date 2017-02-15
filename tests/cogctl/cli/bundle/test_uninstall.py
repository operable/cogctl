import pytest
import cogctl.cli.bundle.uninstall as bundle  # TODO: Eww, this import


# TODO: test data with 0.0.9, 0.0.10 -> 10 is most recent
# TODO: when disabling a bundle, print what version you just disabled

pytestmark = pytest.mark.usefixtures("mocks")


def test_uninstall_existing_bundle(cogctl):
    result = cogctl(bundle.uninstall, ["enabled_bundle", "0.0.1"])

    assert result.exit_code == 0
    assert result.output == """\
Uninstalled enabled_bundle 0.0.1
"""


def test_uninstall_nonexistent_bundle(cogctl):
    result = cogctl(bundle.uninstall, ["not_a_bundle", "0.0.1"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: uninstall [OPTIONS] NAME [VERSION]

Error: Invalid value for "name": Bundle 'not_a_bundle' not found
"""


def test_uninstall_enabled_bundle(cogctl):
    result = cogctl(bundle.uninstall, ["enabled_bundle", "0.0.2"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: uninstall [OPTIONS] NAME [VERSION]

Error: Invalid value for "version": Cannot uninstall enabled version. Please disable the bundle first
"""  # noqa: E501


def test_uninstall_bundle_without_version(cogctl):
    result = cogctl(bundle.uninstall, ["enabled_bundle"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: uninstall [OPTIONS] NAME [VERSION]

Error: Invalid value for "version": Can't uninstall without specifying a version, or --incompatible, --all, --clean
"""  # noqa: E501


def test_uninstall_bundle_with_nonexistent_version(cogctl):
    result = cogctl(bundle.uninstall, ["enabled_bundle", "100.0.0"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: uninstall [OPTIONS] NAME [VERSION]

Error: Invalid value for "version": No version 100.0.0 found for enabled_bundle
"""


def test_uninstall_bundle_with_invalid_version(cogctl):
    result = cogctl(bundle.uninstall, ["enabled_bundle", "not_a_version"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: uninstall [OPTIONS] NAME [VERSION]

Error: Invalid value for "version": Versions must be of the form 'major.minor.patch'
"""  # noqa: E501


def test_uninstall_clean_for_enabled_bundle(cogctl):
    result = cogctl(bundle.uninstall, ["enabled_bundle", "--clean"])

    assert result.exit_code == 0
    assert result.output == """\
Uninstalled enabled_bundle 0.0.1
Uninstalled enabled_bundle 0.0.3
"""


def test_uninstall_clean_for_disabled_bundle(cogctl):
    result = cogctl(bundle.uninstall, ["disabled_bundle", "--clean"])

    assert result.exit_code == 0
    assert result.output == """\
Uninstalled disabled_bundle 0.0.4
Uninstalled disabled_bundle 0.0.5
Uninstalled disabled_bundle 0.0.6
"""


def test_uninstall_incompatible(cogctl):
    result = cogctl(bundle.uninstall, ["has_incompatible_versions",
                                       "--incompatible"])

    assert result.exit_code == 0
    assert result.output == """\
Uninstalled has_incompatible_versions 0.0.7
Uninstalled has_incompatible_versions 0.0.8
"""


def test_uninstall_incompatible_by_version(cogctl):
    result = cogctl(bundle.uninstall, ["has_incompatible_versions", "0.0.7"])

    assert result.exit_code == 0
    assert result.output == """\
Uninstalled has_incompatible_versions 0.0.7
"""


def test_uninstall_all(cogctl):
    result = cogctl(bundle.uninstall, ["disabled_bundle", "--all"])

    assert result.exit_code == 0
    assert result.output == """\
Uninstalled disabled_bundle 0.0.4
Uninstalled disabled_bundle 0.0.5
Uninstalled disabled_bundle 0.0.6
"""


def test_uninstall_cannot_specify_version_with_options(cogctl):
    result = cogctl(bundle.uninstall, ["disabled_bundle", "0.0.4", "--all"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: uninstall [OPTIONS] NAME [VERSION]

Error: Invalid value for "version": Do not give a version if using --incompatible, --all, --clean
"""  # noqa: E501


def test_uninstall_cannot_delete_all_if_enabled(cogctl):
    result = cogctl(bundle.uninstall, ["enabled_bundle", "--all"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: uninstall [OPTIONS] NAME [VERSION]

Error: Invalid value for "bundle": enabled_bundle 0.0.2 is currently enabled. Please disable the bundle first.
"""  # noqa: E501


def test_uninstall_nothing_to_uninstall(cogctl):
    result = cogctl(bundle.uninstall, ["enabled_bundle", "--incompatible"])

    assert result.exit_code == 0
    assert result.output == """\
Nothing to uninstall
"""

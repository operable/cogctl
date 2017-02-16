import cogctl as cogctl_module
from cogctl.cli.version import version


def test_version(cogctl):
    result = cogctl(version)

    assert result.exit_code == 0
    assert result.output == """\
cogctl {} (build: unknown)
""".format(cogctl_module.__version__)

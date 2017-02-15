import os
import pytest
from click.testing import CliRunner
from functools import partial
from cogctl.cli.main import cli


@pytest.fixture
def cogctl():
    """Set up a test runner from the true root of the application, instead
    of testing individual commands directly.

    """
    runner = CliRunner()
    with runner.isolated_filesystem():
        yield partial(runner.invoke,
                      cli,
                      catch_exceptions=False)


@pytest.fixture
def config_file(cogctl):
    # This is written in the context of the test runner's isolated
    # filesystem
    with open("config", "w") as f:
        f.write("""\
[defaults]
profile=default_profile

[default_profile]
host=default_host
password=default_password
port=4000
secure=false
user=default_user

# A comment about the testing profile
[testing]
host=cog.testing.com
password="testpass#with_a_hash"
port=1234
secure=true
user=tester

[new-style]
url=https://cog.newstyle.com:1234
user=new_user
password=new_password
""")

    return "{}/{}".format(os.getcwd(), "config")


def test_migrate_configuration(cogctl, config_file):
    result = cogctl(["--config-file", config_file,
                     "upgrade-configuration"])

    assert result.exit_code == 0
    assert result.output == ""

    with open(config_file) as f:
        migrated_content = f.read()

    assert migrated_content == """\
[defaults]
profile = default_profile

[default_profile]
password = default_password
url = http://default_host:4000
user = default_user

# A comment about the testing profile
[testing]
password = "testpass#with_a_hash"
url = https://cog.testing.com:1234
user = tester

[new-style]
password = new_password
url = https://cog.newstyle.com:1234
user = new_user
"""

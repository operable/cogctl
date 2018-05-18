import os
import pytest
from click.testing import CliRunner
from cogctl.cli.main import cli
from functools import partial


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
    with open("config", "w") as f:
        f.write("""\
[defaults]
profile = default_profile

[default_profile]
host = default_host
password = default_password
port = 4000
secure = false
user = default_user

[testing]
host = cog.testing.com
password = testpass
port = 1234
secure = true
user = tester

[new-style]
url = https://cog.newstyle.com:1234
user = new_user
password = new_password
""")

    return "{}/{}".format(os.getcwd(), "config")


def test_list_profiles(cogctl, config_file):
    result = cogctl(["--config-file", config_file,
                     "profile"])

    assert result.exit_code == 0
    assert result.output == """\
Profile: default_profile (default)
User: default_user
URL: http://default_host:4000

Profile: new-style
User: new_user
URL: https://cog.newstyle.com:1234

Profile: testing
User: tester
URL: https://cog.testing.com:1234

"""


def test_add_new_profile(cogctl, config_file):
    result = cogctl(["--config-file", config_file,
                     "profile", "create",
                     "my_new_profile",
                     "https://myserver.com:1234",
                     "my_user", "my_password"])

    assert result.exit_code == 0
    assert result.output == ""

    with open(config_file) as f:
        contents = f.read()

    assert contents == """\
[defaults]
profile = default_profile

[default_profile]
host = default_host
password = default_password
port = 4000
secure = false
user = default_user

[testing]
host = cog.testing.com
password = testpass
port = 1234
secure = true
user = tester

[new-style]
url = https://cog.newstyle.com:1234
user = new_user
password = new_password
[my_new_profile]
password = my_password
url = https://myserver.com:1234
user = my_user
"""


def test_change_default_profile(cogctl, config_file):
    result = cogctl(["--config-file", config_file,
                     "profile", "default",
                     "testing"])

    assert result.exit_code == 0
    assert result.output == ""

    with open(config_file) as f:
        contents = f.read()

    assert contents == """\
[defaults]
profile = testing

[default_profile]
host = default_host
password = default_password
port = 4000
secure = false
user = default_user

[testing]
host = cog.testing.com
password = testpass
port = 1234
secure = true
user = tester

[new-style]
url = https://cog.newstyle.com:1234
user = new_user
password = new_password
"""


def test_change_default_invalid_profile(cogctl, config_file):
    result = cogctl(["--config-file", config_file,
                     "profile", "default",
                     "missing"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: cli profile default [OPTIONS] NAME

Error: Invalid value for \"name\": \"missing\" was not found
"""

    with open(config_file) as f:
        contents = f.read()

    assert contents == """\
[defaults]
profile = default_profile

[default_profile]
host = default_host
password = default_password
port = 4000
secure = false
user = default_user

[testing]
host = cog.testing.com
password = testpass
port = 1234
secure = true
user = tester

[new-style]
url = https://cog.newstyle.com:1234
user = new_user
password = new_password
"""

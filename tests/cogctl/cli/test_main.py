import click
import os
import pytest
from click.testing import CliRunner
from cogctl.cli.main import cli
from functools import partial


@cli.command()
@click.pass_obj
def dumper(state):
    """Testing command used to help test some of the top-level
    configuration munging we do.

    The root of the CLI app doesn't do anything but return the help
    string if no subcommands are given, so this is a convenient way to
    ensure that profile information is set properly when subcommands
    are passed.

    """
    if state.profile:
        click.echo("URL: {}".format(state.profile['url']))
        click.echo("User: {}".format(state.profile['user']))
        click.echo("Password: {}".format(state.profile['password']))

    click.echo("Verbosity: {}".format(state.verbosity))
    click.echo("Config File: {}".format(state.configuration.filename))


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

[testing]
host=cog.testing.com
password=testpass
port=1234
secure=true
user=tester

[new-style]
url=https://cog.newstyle.com:1234
user=new_user
password=new_password
""")

    return "{}/{}".format(os.getcwd(), "config")


########################################################################


def test_with_no_nonexistent_config_file(cogctl):
    result = cogctl(["--config-file", "not_there_yet", "dumper"])

    assert result.exit_code == 0
    assert result.output == """\
Verbosity: 0
Config File: {}/not_there_yet
""".format(os.getcwd())


def test_reading_the_default_profile(cogctl, config_file):
    result = cogctl(["--config-file", config_file, "dumper"])

    assert result.exit_code == 0
    assert result.output == """\
URL: http://default_host:4000
User: default_user
Password: default_password
Verbosity: 0
Config File: {}
""".format(config_file)


def test_reading_a_missing_default_profile(cogctl):
    with open("config", "w") as f:
        f.write("""\
[default_profile]
host=default_host
password=default_password
port=4000
secure=false
user=default_user
""")

    result = cogctl(["--config-file", "config", "dumper"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: cli [OPTIONS] COMMAND [ARGS]...

Error: Invalid value for "--config-file": The given configuration file is not valid
"""


def test_specifying_a_profile_that_exists(cogctl, config_file):
    result = cogctl(["--config-file", config_file,
                     "--profile", "testing", "dumper"])

    assert result.exit_code == 0
    assert result.output == """\
URL: https://cog.testing.com:1234
User: tester
Password: testpass
Verbosity: 0
Config File: {}
""".format(config_file)


def test_specifying_a_new_style_profile(cogctl, config_file):
    # This shows that if there is a new-style config section (i.e., just
    # "url", not "host/port/secure"), it still gets processed
    # correctly.
    #
    # This is less important if we ensure that all config sections are
    # consistent within a file.
    result = cogctl(["--config-file", config_file,
                     "--profile", "new-style", "dumper"])

    assert result.exit_code == 0
    assert result.output == """\
URL: https://cog.newstyle.com:1234
User: new_user
Password: new_password
Verbosity: 0
Config File: {}
""".format(config_file)


def test_specifying_a_nonexistent_profile(cogctl, config_file):
    result = cogctl(["--config-file", config_file,
                     "--profile", "not_a_profile", "dumper"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: cli [OPTIONS] COMMAND [ARGS]...

Error: Invalid value for "--profile": Profile 'not_a_profile' was not found in configuration file '{}'
""".format(config_file)  # noqa: E501


def test_with_profile_and_nonexistent_config_file(cogctl):
    result = cogctl(["--config-file", "not_there_yet",
                     "--profile", "my_profile",
                     "dumper"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: cli [OPTIONS] COMMAND [ARGS]...

Error: Invalid value for "--profile": Profile 'my_profile' was not found in configuration file '{}/{}'
""".format(os.getcwd(), "not_there_yet")  # noqa: E501


def test_overriding_the_url(cogctl, config_file):
    result = cogctl(["--config-file", config_file,
                     "--url", "https://override.com:9999",
                     "dumper"])

    assert result.exit_code == 0
    assert result.output == """\
URL: https://override.com:9999
User: default_user
Password: default_password
Verbosity: 0
Config File: {}
""".format(config_file)


def test_overriding_the_user(cogctl, config_file):
    result = cogctl(["--config-file", config_file,
                     "--user", "override_user",
                     "dumper"])

    assert result.exit_code == 0
    assert result.output == """\
URL: http://default_host:4000
User: override_user
Password: default_password
Verbosity: 0
Config File: {}
""".format(config_file)


def test_overriding_the_password(cogctl, config_file):
    result = cogctl(["--config-file", config_file,
                     "--password", "override_password",
                     "dumper"])

    assert result.exit_code == 0
    assert result.output == """\
URL: http://default_host:4000
User: default_user
Password: override_password
Verbosity: 0
Config File: {}
""".format(config_file)


def test_profile_can_be_specified_entirely_on_commandline(cogctl):
    result = cogctl(["--config-file", "not_a_file_yet",
                     "--url", "https://override.com:1234",
                     "--user", "override_user",
                     "--password", "override_password",
                     "dumper"])

    assert result.exit_code == 0
    assert result.output == """\
URL: https://override.com:1234
User: override_user
Password: override_password
Verbosity: 0
Config File: {}/{}
""".format(os.getcwd(), "not_a_file_yet")


def test_setting_verbosity(cogctl):
    result = cogctl(["--config-file", "not_there_yet",
                     "-v", "-v", "-v",
                     "dumper"])

    assert result.exit_code == 0
    assert result.output == """\
Verbosity: 3
Config File: {}/not_there_yet
""".format(os.getcwd())

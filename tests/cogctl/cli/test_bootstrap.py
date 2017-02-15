import responses
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


def test_bootstrap_status_unbootstrapped(cogctl):
    with responses.RequestsMock() as rsps:
        rsps.add(responses.GET, "http://localhost:4000/v1/bootstrap",
                 json={'bootstrap': {'bootstrap_status': False}},
                 status=200)

        result = cogctl(["bootstrap", "--status"])

    assert result.exit_code == 0
    assert result.output == """\
Status: Not bootstrapped
"""


def test_bootstrap_status_bootstrapped(cogctl):
    with responses.RequestsMock() as rsps:
        rsps.add(responses.GET, "http://localhost:4000/v1/bootstrap",
                 json={'bootstrap': {'bootstrap_status': True}},
                 status=200)

        result = cogctl(["bootstrap", "--status"])

    assert result.exit_code == 0
    assert result.output == """\
Status: bootstrapped
"""


def test_bootstrap_unbootstrapped_server(cogctl):
    with responses.RequestsMock() as rsps:
        rsps.add(responses.POST, "http://localhost:4000/v1/bootstrap",
                 json={'bootstrap':
                       {"username": "testuser",
                        "password": "supersecret"}},
                 status=200)

        result = cogctl(["--config-file", "test_config",
                         "bootstrap"])

    with open("test_config") as f:
        contents = f.read()

    assert result.exit_code == 0
    assert contents == """\
[defaults]
profile = localhost
[localhost]
password = supersecret
url = http://localhost:4000
user = testuser
"""


def test_bootstrap_unbootstrapped_server_with_url(cogctl):
    url = "https://cog.mycompany.com"

    with responses.RequestsMock() as rsps:
        rsps.add(responses.POST, "{}/v1/bootstrap".format(url),
                 json={'bootstrap':
                       {"username": "admin",
                        "password": "such_a_secret"}},
                 status=200)

        result = cogctl(["--config-file", "test_config",
                         "bootstrap", url])

    with open("test_config") as f:
        contents = f.read()

    assert result.exit_code == 0
    assert contents == """\
[defaults]
profile = cog.mycompany.com
[cog.mycompany.com]
password = such_a_secret
url = {}
user = admin
""".format(url)


def test_bootstrap_unbootstrapped_server_with_other_profiles_in_config_file(cogctl):
    config_file_name = "existing_config"
    with open(config_file_name, "w") as f:
        f.write("""\
[defaults]
profile=localhost

[localhost]
password=local_password
user=local_user
url=http://localhost:4000
""")

    url = "https://cog.mycompany.com"
    with responses.RequestsMock() as rsps:
        rsps.add(responses.POST, "{}/v1/bootstrap".format(url),
                 json={'bootstrap':
                       {"username": "admin",
                        "password": "such_a_secret"}},
                 status=200)

        result = cogctl(["--config-file", config_file_name,
                         "bootstrap", url])

    with open(config_file_name) as f:
        contents = f.read()

    assert result.exit_code == 0
    assert contents == """\
[defaults]
profile = localhost

[localhost]
password = local_password
user = local_user
url = http://localhost:4000
[cog.mycompany.com]
password = such_a_secret
url = {}
user = admin
""".format(url)

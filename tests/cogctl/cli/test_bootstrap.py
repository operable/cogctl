import os
from click.testing import CliRunner
import cogctl.cli.bootstrap
from cogctl.cli.state import State
import responses


def test_bootstrap_status_unbootstrapped():
    with responses.RequestsMock() as rsps:
        rsps.add(responses.GET, "http://localhost:4000/v1/bootstrap",
                 json={'bootstrap': {'bootstrap_status': False}},
                 status=200)

        runner = CliRunner()
        result = runner.invoke(cogctl.cli.bootstrap.bootstrap, ['--status'])

    assert 'Status: Not bootstrapped' in result.output
    assert result.exit_code == 0


def test_bootstrap_status_bootstrapped():
    with responses.RequestsMock() as rsps:
        rsps.add(responses.GET, "http://localhost:4000/v1/bootstrap",
                 json={'bootstrap': {'bootstrap_status': True}},
                 status=200)

        runner = CliRunner()
        result = runner.invoke(cogctl.cli.bootstrap.bootstrap, ['--status'])

    assert 'Status: bootstrapped' in result.output
    assert result.exit_code == 0


def test_bootstrap_unbootstrapped_server():
    with responses.RequestsMock() as rsps:
        rsps.add(responses.POST, "http://localhost:4000/v1/bootstrap",
                 json={'bootstrap':
                       {"username": "testuser",
                        "password": "supersecret"}},
                 status=200)

        runner = CliRunner()

        with runner.isolated_filesystem():
            state = State()
            state.config_file = os.path.abspath(os.path.expanduser("tempfile"))

            result = runner.invoke(cogctl.cli.bootstrap.bootstrap, obj=state)

            with open(state.config_file) as f:
                contents = f.read()

    assert result.exit_code == 0
    assert contents == """[defaults]
profile = localhost

[localhost]
host = localhost
port = 4000
secure = false
user = testuser
password = supersecret

"""

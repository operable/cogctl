import responses
import pytest
import json
import os

import cogctl.cli.bundle.install as bundle  # TODO: Eww, this import


@pytest.fixture
def valid_config(request):
    """Returns a bundle configuration, using the name of the test function
    as the name of the bundle being installed.
    """
    return """\
---
cog_bundle_version: 4
name: {0}
description: a fake bundle for testing bundle installation in cogctl
version: 1.0.0
docker:
  image: mycompany/{0}
  tag: 1.0.0
commands:
  echo:
    executable: "/bundle/echo"
    description: Echoes what it's passed
    rules:
    - allow
""".format(request.function.__name__)


@pytest.fixture
def already_installed_valid_config(request):
    """Returns a bundle configuration, using the name of the test function
    as the name of the bundle being installed.
    """
    return """\
---
cog_bundle_version: 4
name: {0}
description: a fake bundle for testing bundle installation in cogctl
version: 2.0.0
docker:
  image: mycompany/{0}
  tag: 2.0.0
commands:
  echo:
    executable: "/bundle/echo"
    description: Echoes what it's passed
    rules:
    - allow
""".format(request.function.__name__)


@pytest.mark.usefixtures("mocks")
def test_install_bundle_from_file(cogctl, valid_config):
    with open("my_config.yaml", "w") as f:
        f.write(valid_config)

    result = cogctl(bundle.install, ["my_config.yaml"])

    assert result.exit_code == 0
    assert result.output == """\
Installed test_install_bundle_from_file version 1.0.0
"""


@pytest.mark.usefixtures("mocks")
def test_install_bundle_from_registry(cogctl):
    result = cogctl(bundle.install, ["twitter"])

    assert result.exit_code == 0
    # TODO: Need to say what version was installed
    assert result.output == """\
Installed twitter version 10.0.0
"""


@pytest.mark.usefixtures("mocks")
def test_bundle_install_reading_from_stdin(cogctl, valid_config):
    result = cogctl(bundle.install, ["-"],
                    input=valid_config)

    assert result.exit_code == 0
    assert result.output == """\
Installed test_bundle_install_reading_from_stdin version 1.0.0
"""


@pytest.mark.usefixtures("mocks")
def test_install_version_not_allowed_installing_from_file(cogctl, valid_config):  # noqa: E501
    with open("my_config.yaml", "w") as f:
        f.write(valid_config)

    result = cogctl(bundle.install, ["my_config.yaml", "1.0.0"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: install [OPTIONS] BUNDLE_OR_PATH [VERSION]

Error: Invalid value for "version": Versions may only be set for bundles loaded from the Bundle Warehouse (https://warehouse.operable.io)
"""  # noqa: E501


@pytest.mark.usefixtures("mocks")
def test_install_bundle_from_registry_with_version(cogctl):
    result = cogctl(bundle.install, ["twitter", "1.0.0"])

    assert result.exit_code == 0
    assert result.output == """\
Installed twitter version 1.0.0
"""


@pytest.mark.usefixtures("mocks")
def test_install_bundle_with_version_must_be_valid(cogctl):
    result = cogctl(bundle.install, ["twitter", "not_a_version"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: install [OPTIONS] BUNDLE_OR_PATH [VERSION]

Error: Invalid value for "version": Versions must be of the form 'major.minor.patch'
"""  # noqa: E501


@pytest.mark.usefixtures("mocks")
def test_install_with_version_must_have_no_prerelease_or_metadata(cogctl):
    result = cogctl(bundle.install, ["twitter", "1.0.0-beta.2"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: install [OPTIONS] BUNDLE_OR_PATH [VERSION]

Error: Invalid value for "version": Versions must be of the form 'major.minor.patch'
"""  # noqa: E501


@pytest.mark.usefixtures("mocks")
def test_install_bundle_from_registry_with_nonexistent_version(cogctl):
    result = cogctl(bundle.install, ["twitter", "6.6.6"])

    assert result.exit_code == 1
    assert result.output == """\
Error: Bundle \"twitter\" version \"6.6.6\" not found.
"""


@pytest.mark.usefixtures("mocks")
def test_install_bundle_from_registry_fails_if_version_exists(cogctl):
    result = cogctl(bundle.install, ["twitter", "2.0.0"])

    assert result.exit_code == 1
    assert result.output == """\
Error: Could not save bundle. version has already been taken
"""


@pytest.mark.usefixtures("mocks")
def test_install_from_file_fails_if_version_exists(cogctl,
                                                   already_installed_valid_config):  # noqa: E501
    with open("my_config.yaml", "w") as f:
        f.write(already_installed_valid_config)

    result = cogctl(bundle.install, ["my_config.yaml"])

    assert result.exit_code == 1
    assert result.output == """\
Error: Could not save bundle. version has already been taken
"""


@pytest.mark.usefixtures("mocks")
def test_install_bundle_force(cogctl, already_installed_valid_config):
    with open("my_config.yaml", "w") as f:
        f.write(already_installed_valid_config)

    result = cogctl(bundle.install, ["my_config.yaml", "--force"])

    assert result.exit_code == 0
    assert result.output == """\
Installed test_install_bundle_force version 2.0.0
"""


@pytest.mark.usefixtures("mocks")
def test_install_bundle_from_registry_with_force_fails(cogctl):
    result = cogctl(bundle.install, ["twitter", "--force"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: install [OPTIONS] BUNDLE_OR_PATH [VERSION]

Error: Invalid value for "--force" / "-f": Cannot force-install bundles from the Bundle Warehouse (https://warehouse.operable.io)
"""  # noqa: E501


@pytest.mark.usefixtures("mocks")
def test_install_bundle_from_registry_with_templates_fails(cogctl):
    os.mkdir("my_templates")

    result = cogctl(bundle.install,
                    ["twitter", "--templates", "my_templates"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: install [OPTIONS] BUNDLE_OR_PATH [VERSION]

Error: Invalid value for "--templates" / "-t": Cannot add templates to bundles installed from the Bundle Warehouse (https://warehouse.operable.io)
"""  # noqa: E501


@pytest.mark.usefixtures("mocks")
def test_install_with_relay_groups(cogctl):
    result = cogctl(bundle.install,
                    ["twitter", "-r", "group_1"])

    assert result.exit_code == 0
    assert result.output == """\
Installed twitter version 10.0.0
Assigned twitter to relay group group_1
"""


@pytest.mark.usefixtures("mocks")
def test_install_with_relay_groups_accepts_comma_delimited(cogctl):
    result = cogctl(bundle.install,
                    ["twitter",
                     "-r", "group_1",
                     "-r", "group_2,group_3"])

    assert result.exit_code == 0
    assert result.output == """\
Installed twitter version 10.0.0
Assigned twitter to relay group group_1
Assigned twitter to relay group group_2
Assigned twitter to relay group group_3
"""


@pytest.mark.usefixtures("mocks")
def test_install_with_nonexistent_relay_groups(cogctl):
    result = cogctl(bundle.install,
                    ["twitter", "-r", "not_a_real_group"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: install [OPTIONS] BUNDLE_OR_PATH [VERSION]

Error: Invalid value for "--relay-group" / "-r": The following relay groups do not exist: not_a_real_group
"""  # noqa: E501


@pytest.mark.usefixtures("mocks")
def test_install_bundle_enable(cogctl):
    result = cogctl(bundle.install,
                    ["twitter", "-r", "group_1", "-e"])

    assert result.exit_code == 0
    # TODO: Ugh, this version
    assert result.output == """\
Installed twitter version 10.0.0
Assigned twitter to relay group group_1
Enabled twitter version twitter_VERSION_ID
"""


def test_install_with_template_files(cogctl, valid_config, cli_state):
    # This is the only test in the module that *doesn't* use the mocks
    # fixture.
    #
    # Because of the nature of this test, we need to add some very
    # specific handling into the POST /v1/bundles HTTP
    # request. Instead of shoving that into the mock fixture, and
    # effectively splitting this test across two files, we'll just
    # handle all the mocking directly in the test (there are only 2
    # requests, so it's not too bad).

    template_name = "test_template"
    template_body = "Result: ~$results[0]~"

    # Create the template file
    with open("my_config.yaml", "w") as f:
        f.write(valid_config)

    os.mkdir("my_template_files")

    with open("my_template_files/%s.greenbar" % template_name, "w") as f:
        f.write(template_body)

    # Mock callback function
    def install_callback(request):
        payload = json.loads(request.body.decode())
        config = payload['bundle']['config']

        # This is where the actual test happens... we want to
        # ensure that the template from the filesystem actually gets
        # pulled into the config that gets sent to the Cog server.
        actual_content = config.get("templates", {}).get(template_name)
        if actual_content != template_body:
            raise Exception("Expected '{}' for template content, "
                            "but got '{}'".format(
                                template_body,
                                actual_content))  # pragma: nocover

        body = {"bundle_version":
                {"id": "THE_ID_OF_THE_VERSION",
                 "bundle_id": "THE_ID_OF_THE_BUNDLE",
                 "name": config['name'],
                 "version": config['version']}}
        return (201, {'content-type': 'application/json'},
                json.dumps(body))

    # Actually set up the mocks
    with responses.RequestsMock() as r:
        root = cli_state.profile["url"]

        r.add(responses.POST, root + "/v1/token",
              json={"token": {"value": "abcdef0123456789"}},
              status=201)

        r.add_callback(responses.POST, root + "/v1/bundles",
                       callback=install_callback,
                       content_type="application/json")

        result = cogctl(bundle.install, ["my_config.yaml",
                                         "--templates", "my_template_files"])

    assert result.exit_code == 0
    assert result.output == """\
Installed test_install_with_template_files version 1.0.0
"""


@pytest.mark.usefixtures("mocks")
def test_install_with_templates_fails_with_missing_directory(cogctl, valid_config):  # noqa: E501
    with open("my_config.yaml", "w") as f:
        f.write(valid_config)

    result = cogctl(bundle.install,
                    ["my_config.yaml", "--templates", "not_a_dir"])

    assert result.exit_code == 2
    assert result.output == """\
Usage: install [OPTIONS] BUNDLE_OR_PATH [VERSION]

Error: Invalid value for "--templates" / "-t": Directory "not_a_dir" does not exist.
"""  # noqa: E501

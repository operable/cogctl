import pytest
import cogctl.cli.bundle.config as bundle_config


@pytest.fixture
def valid_config_path(cogctl):
    path = "bundle_config.yaml"

    with open(path, "w") as f:
        f.write("""\
---
config1: value1
config2: value2
""")

    return path


pytestmark = pytest.mark.usefixtures("mocks")


def test_create_base_config(cogctl, valid_config_path):
    result = cogctl(bundle_config.create, ["has_configs",
                                           valid_config_path])
    assert result.exit_code == 0
    assert result.output == """\
Created base layer for 'has_configs' bundle
"""


def test_create_room_config(cogctl, valid_config_path):
    result = cogctl(bundle_config.create, ["has_configs",
                                           valid_config_path,
                                           "--layer", "room/engineering"])
    assert result.exit_code == 0
    assert result.output == """\
Created room/engineering layer for 'has_configs' bundle
"""


def test_create_user_config(cogctl, valid_config_path):
    result = cogctl(bundle_config.create, ["has_configs",
                                           valid_config_path,
                                           "--layer", "user/alice"])
    assert result.exit_code == 0
    assert result.output == """\
Created user/alice layer for 'has_configs' bundle
"""


def test_create_from_stdin(cogctl):
    input = """\
---
config1: value1
config2: value2
"""

    result = cogctl(bundle_config.create,
                    ["has_configs", "-"],
                    input=input)

    assert result.exit_code == 0
    assert result.output == """\
Created base layer for 'has_configs' bundle
"""


def test_create_fails_with_bad_yaml(cogctl):
    input = """\
LOLWUT:
    - this:
    - isn't
  yaml

"""

    result = cogctl(bundle_config.create,
                    ["has_configs", "-"],
                    input=input)

    assert result.exit_code == 2
    assert result.output == """\
Usage: create [OPTIONS] BUNDLE_NAME CONFIG_FILE

Error: Invalid value for "config_file": Invalid YAML
"""


def test_creat_fails_with_invalid_layer(cogctl, valid_config_path):
    result = cogctl(bundle_config.create, ["has_configs",
                                           valid_config_path,
                                           "--layer", "not/really-a/LAYER"])
    assert result.exit_code == 2
    assert result.output == """\
Usage: create [OPTIONS] BUNDLE_NAME CONFIG_FILE

Error: Invalid value for "--layer" / "-l": Must specify layer as 'base', 'room/$NAME', or 'user/$NAME'
"""  # noqa: E501

import os
import pytest
from cogctl.cli.config import CogctlConfig


@pytest.fixture
def classic_config(tmpdir):
    config_path = tmpdir.join("config")

    config_path.write("""\
[defaults]
profile=localhost

[localhost]
host=localhost
password=sooperseekrit
port=4000
secure=false
user=admin

[testing]
host=cog.testing.com
password=testpass
port=1234
secure=true
user=tester
""")

    return CogctlConfig(config_path.__str__())


@pytest.fixture
def config_with_comments(tmpdir):
    config_path = tmpdir.join("config")

    config_path.write("""\
[defaults]
profile=localhost

# Here's where the magic happens
[localhost]
host=localhost
password="sooperseekrit#with_a_hash"
port=4000
secure=false
user=admin

[testing]
host=cog.testing.com # what an interesting hostname

# This is a very interesting password, indeed!
password=testpass
port=1234
secure=true
user=tester

# Let's say some other stuff here,
# for no real reason at all, but to
# have additional comments. Fun!
""")

    return CogctlConfig(config_path.__str__())


def test_has_default(classic_config):
    default = classic_config.default()
    assert {'password': 'sooperseekrit',
            'url': 'http://localhost:4000',
            'user': 'admin'} == default


def test_access_profile_by_name(classic_config):
    profile = classic_config.profile("localhost")
    assert {'password': 'sooperseekrit',
            'url': 'http://localhost:4000',
            'user': 'admin'} == profile


def test_add_new_profile(classic_config):
    new_profile = {"password": "a_new_password",
                   "user": "a_new_user",
                   "url": "https://cog.mycompany.com"}

    classic_config.add("new_profile", new_profile)

    retrieved = classic_config.profile("new_profile")
    assert {"password": "a_new_password",
            "user": "a_new_user",
            "url": "https://cog.mycompany.com"} == retrieved


def test_list_profiles(classic_config):
    assert classic_config.profiles() == ["localhost", "testing"]


def test_writing(classic_config):
    # Add something to write out
    new_profile = {"user": "a_new_user",
                   "password": "a_new_password",
                   "url": "https://cog.mycompany.com"}

    classic_config.add("new_profile", new_profile)
    classic_config.write()

    with open(classic_config.filename) as f:
        content = f.read()

    # Note that spacing between sections is preserved, but space is
    # added around "=". New sections are added with no intervening
    # lines.
    #
    # New sections are also added in the "new style" (url instead of
    # secure/host/port).
    assert content == """\
[defaults]
profile = localhost

[localhost]
host = localhost
password = sooperseekrit
port = 4000
secure = false
user = admin

[testing]
host = cog.testing.com
password = testpass
port = 1234
secure = true
user = tester
[new_profile]
password = a_new_password
url = https://cog.mycompany.com
user = a_new_user
"""


def test_add_can_create_a_new_file(tmpdir):
    config_path = tmpdir.join("config")
    assert not os.path.isfile(config_path.__str__())

    config = CogctlConfig(config_path.__str__())
    new_profile = {"user": "a_new_user",
                   "password": "a_new_password",
                   "url": "https://cog.mycompany.com"}

    config.add("new_profile", new_profile)
    config.write()

    with open(config.filename) as f:
        content = f.read()

    assert content == """\
[defaults]
profile = new_profile
[new_profile]
password = a_new_password
url = https://cog.mycompany.com
user = a_new_user
"""


def test_config_files_must_have_a_default_section(tmpdir):
    config_path = tmpdir.join("config")
    config_path.write("""\
[localhost]
host=localhost
password=sooperseekrit
port=4000
secure=false
user=admin
""")

    with pytest.raises(KeyError,
                       message="Expected a KeyError when determining "
                       "the default profile"):
        CogctlConfig(config_path.__str__())


def test_can_update_old_profile(classic_config):
    assert {'host': 'localhost',
            'password': 'sooperseekrit',
            'port': '4000',
            'secure': 'false',
            'user': 'admin'} == classic_config._config["localhost"]

    classic_config.update_profile("localhost")

    assert {'url': 'http://localhost:4000',
            'password': 'sooperseekrit',
            'user': 'admin'} == classic_config._config["localhost"]


def test_comments_round_trip(config_with_comments):
    config_with_comments.write()

    with open(config_with_comments.filename) as f:
        content = f.read()

    assert content == """\
[defaults]
profile = localhost

# Here's where the magic happens
[localhost]
host = localhost
password = "sooperseekrit#with_a_hash"
port = 4000
secure = false
user = admin

[testing]
host = cog.testing.com# what an interesting hostname

# This is a very interesting password, indeed!
password = testpass
port = 1234
secure = true
user = tester

# Let's say some other stuff here,
# for no real reason at all, but to
# have additional comments. Fun!
"""


def test_comment_characters_in_values_can_be_quoted(config_with_comments):
    password = config_with_comments.profile("localhost")["password"]
    assert password == "sooperseekrit#with_a_hash"


def test_set_default_updates_default(classic_config):
    classic_config.set_default("testing")
    assert classic_config.default() == {'password': 'testpass',
                                        'url': 'https://cog.testing.com:1234',
                                        'user': 'tester'}


def test_set_default_missing_profile(classic_config):
    with pytest.raises(KeyError):
        classic_config.set_default("missing")

from cogctl.cli import table


def test_table_render_dict_default():
    d = {"first_name": "Patrick",
         "last_name": "Van Stee",
         "email_address": "patrick@operable.io",
         "username": "vanstee"}
    result = table.render_dict(d)
    assert result == """\
Email Address  patrick@operable.io
First Name     Patrick
Last Name      Van Stee
Username       vanstee\
"""


def test_table_render_dict_with_names():
    d = {"first_name": "Patrick",
         "last_name": "Van Stee",
         "email_address": "patrick@operable.io",
         "username": "vanstee"}
    result = table.render_dict(d, ["first_name", "last_name"])
    assert result == """\
First Name  Patrick
Last Name   Van Stee\
"""


def test_table_render_dicts_default():
    dicts = [{"first_name": "Patrick",
              "last_name": "Van Stee",
              "email_address": "patrick@operable.io",
              "username": "vanstee"},
             {"first_name": "Kevin",
              "last_name": "Smith",
              "email_address": "kevsmith@operable.io",
              "username": "kevsmith"}]
    result = table.render_dicts(dicts)
    assert result == """\
EMAIL ADDRESS         FIRST NAME  LAST NAME  USERNAME
patrick@operable.io   Patrick     Van Stee   vanstee
kevsmith@operable.io  Kevin       Smith      kevsmith\
"""


def test_table_render_json_with_names():
    dicts = [{"first_name": "Patrick",
              "last_name": "Van Stee",
              "email_address": "patrick@operable.io",
              "username": "vanstee"},
             {"first_name": "Kevin",
              "last_name": "Smith",
              "email_address": "kevsmith@operable.io",
              "username": "kevsmith"}]
    headers = ["first_name", "last_name", "email_address"]
    result = table.render_dicts(dicts, headers)
    assert result == """\
FIRST NAME  LAST NAME  EMAIL ADDRESS
Patrick     Van Stee   patrick@operable.io
Kevin       Smith      kevsmith@operable.io\
"""

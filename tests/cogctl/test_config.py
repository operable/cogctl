import cogctl.cli.config


def test_normalize_entry():
    entry = {"secure": "false",
             "host": "localhost",
             "port": 4000,
             "user": "testuser",
             "password": "supersecret"}

    result = cogctl.cli.config.normalize_entry(entry)
    assert result == {"user": "testuser",
                      "password": "supersecret",
                      "url": "http://localhost:4000"}

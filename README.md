cogctl: Command-Line Administration Interface for Cog
#####################################################

[![Build Status](https://travis-ci.org/operable/cogctl.svg?branch=master)](https://travis-ci.org/operable/cogctl)

`cogctl` is a CLI tool for administering a
[Cog](https://github.com/operable/cog) chat server installation.

# Installation

Binaries for musl-based (e.g. Alpine Linux) and libc-based
(e.g. Ubuntu) Linux distributions, as well as for MacOS are available
on the [latest Cog release
page](https://github.com/operable/cog/releases). If you would like to
build an executable for another platform, read on for how to set up a
local development and build environment.

Once you have a binary, you may run it from anywhere you like; it is
completely self-contained and stand-alone.

# Configuring

`cogctl` uses an INI-formatted configuration file, conventionally
named `.cogctl` in your home directory. This is where you can store
connection credentials to allow `cogctl` to interact with Cog's REST
API.

An example file might look like this:
```
[defaults]
profile = cog

[cog]
password = "seekrit#password"
url = https://cog.mycompany.com:4000
user = me

[preprod]
password = "anotherseekrit#password"
url = https://cog.preprod.mycompany.com:4000
user = me
```

Comments begin with a `#` character; if your password contains a `#`,
surround the entire password in quotes, as illustrated above.

You can store multiple "profiles" in this file, with a different name
for each (here, we have `cog` and `preprod`). Whichever one is noted
as the default (in the `defaults` section) will be used by
`cogctl`. However, you can pass the `--profile=$PROFILE` option to
`cogctl` to use a different set of credentials.

While you can add profiles to this file manually, you can also use the
`cogctl profile create` command to help.

# Getting Help

The `cogctl` executable contains a number of commands and
subcommands. Help is available for all of them by passing the `--help`
option. Start with `cogctl --help`, and go from there.

# Local Development

This is a Python 3 project. On MacOS, you can install this with
Homebrew:

```sh
brew install python3
pip3 install --upgrade pip
```

To set up an isolated development environment, use `virtualenv`. The
`virtualenvwrapper` software makes this easier to manage, and is
described below.

First we'll setup virtualenvwrapper.

```sh
pip3 install virtualenvwrapper
export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
export WORKON_HOME=~/.virtualenvs
source /usr/local/bin/virtualenvwrapper.sh
```

Note: You will probably want to add those env vars and source the
virtualenvwrapper.sh in your shell rc file.

Finally we can set up our virtual env.

```sh
mkvirtualenv cogctl
workon cogctl
add2virtualenv .
make python-deps
```

The final `add2virtualenv` command ensures that the project is on your
`PYTHONPATH`. This allows you to run the `cucumber` acceptance tests
locally (although it runs based on the code directly, and not on the
`pyinstaller`-built binary).

To set up for Cucumber tests, do the following

```sh
make ruby-deps
bin/cucumber
```

To build a stand-alone binary for your current platform, run `make build`.

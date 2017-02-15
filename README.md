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

You'll need to have a Cog server set up and running locally, though.

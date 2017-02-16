import click
import cogctl
import os
import sys


@click.command()
def version():
    """
    Display version and build information.
    """
    version_string = "cogctl %s (build: %s)" % (get_build_tag(),
                                                get_build_version())
    click.echo(version_string)


def get_build_version():
    """
    Return the contents of the file `cogctl/GITSHA`. This is generated
    at build-time and contains the truncated Git SHA of the code being
    built.
    """

    return _read_bundled_file('GITSHA')


def get_build_tag():
    """
    Return the contents of the file `cogctl/GITTAG`. This is generated
    at build-time and contains the Git tag or branch name of the code
    being built. If no file is found then the string `'dev'` is used.
    """

    return _read_bundled_file('GITTAG', default='dev')


def _read_bundled_file(name, default='unknown'):
    """
    Return the contents of a bundled file.

    If running in the context of a PyInstaller-built binary, there
    will be a `frozen` attribute on the `sys` module. When running
    inside such a binary, we'll need to resolve the file's location
    relative to that bundle.
    """
    if getattr(sys, 'frozen', False):
        bundle_dir = sys._MEIPASS
    else:
        bundle_dir = os.path.dirname(cogctl.__file__)

    filename = os.path.join(bundle_dir, name)

    if not os.path.exists(filename):
        return default

    with open(filename) as fh:
        return fh.read().strip()

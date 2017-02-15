import click
import cogctl
import os
import sys


@click.command()
def version():
    """
    Display version and build information.
    """
    version_string = "cogctl %s (build: %s)" % (cogctl.__version__,
                                                get_build_version())
    click.echo(version_string)


def get_build_version():
    """
    Return the contents of the file `cogctl/GITSHA`. This is generated
    at build-time and contains the truncated Git SHA of the code being
    built.

    If running in the context of a PyInstaller-built binary, there
    will be a `frozen` attribute on the `sys` module. When running
    inside such a binary, we'll need to resolve the location of the
    GITSHA file relative to that bundle.
    """

    if getattr(sys, 'frozen', False):
        bundle_dir = sys._MEIPASS  # pragma: nocover
    else:
        bundle_dir = os.path.dirname(cogctl.__file__)

    filename = os.path.join(bundle_dir, 'GITSHA')

    if not os.path.exists(filename):
        return 'unknown'

    with open(filename) as f:  # pragma: nocover
        return f.read().strip()

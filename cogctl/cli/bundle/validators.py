import click
from semantic_version import Version


def ensure_semver(value):
    try:
        semver = Version(value)
        bare_version = "%s.%s.%s" % (semver.major,
                                     semver.minor,
                                     semver.patch)
        if bare_version != value:
            raise click.BadParameter("Versions must be of the "
                                     "form 'major.minor.patch'")
        return bare_version
    except ValueError:
        raise click.BadParameter("Versions must be of the "
                                 "form 'major.minor.patch'")


def validate_bundle_name(ctx, param, value):
    """
    Use this to convert a bundle name into a complete bundle object.
    """
    if value:
        try:
            bundle = ctx.obj.api.bundle(value)
            return bundle
        except StopIteration:
            raise click.BadParameter("Bundle '%s' not found" % value,
                                     param_hint=["name"])

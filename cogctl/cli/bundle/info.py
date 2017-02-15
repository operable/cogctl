import click
import cogctl
import cogctl.cli.table
import cogctl.cli.bundle.validators as validators


def check_version(ctx, param, value):
    if value:
        bundle = ctx.params['bundle']

        # It would be nice to bail out immediately if the version
        # isn't syntactically valid, before even making any API calls,
        # but I'm not sure of a clean way to do that just now.
        value = validators.ensure_semver(value)
        version = next((v for v in bundle['versions']
                        if v['version'] == value), None)
        if version:
            value = ctx.obj.api.bundle_version(bundle['id'], version['id'])
        else:
            raise click.BadParameter(("No version %s found for %s" %
                                      (value, bundle['name'])))

    return value


@click.command()
@click.argument("bundle", callback=validators.validate_bundle_name,
                required=True, metavar="NAME")
@click.argument("version", callback=check_version, required=False)
@cogctl.error_handler
@click.pass_obj
def info(state, bundle, version):
    """Display bundle information.

    If only a bundle name is provided, information on the bundle as a
    whole is presented. If that bundle is also currently enabled,
    details about the version that is currently live is also
    displayed.

    If a version is also provided, details on that specific version
    are presented, regardless of whether it happens to also be
    enabled.
    """

    if version is None:
        # Show information on the enabled bundle
        enabled = bundle['enabled_version']
        table = [["Bundle ID:", bundle['id']]]

        if enabled:
            table.append(["Version ID:", bundle['enabled_version']['id']])

        table.extend([["Name:", bundle['name']],
                      ["Versions:",
                       ", ".join([v['version'] for v in bundle['versions']])],
                      ["Status:", "Enabled" if enabled else "Disabled"]])

        if enabled:
            table.extend([
                ["Enabled Version:", bundle['enabled_version']['version']],
                ["Commands:",
                 ", ".join([c['name']
                            for c in bundle['enabled_version']['commands']])],
                ["Permissions:",
                 ", ".join([p['bundle'] + ":" + p['name']
                            for p
                            in bundle['enabled_version']['permissions']])]
            ])

        if bundle['relay_groups']:
            table.append(["Relay Groups:",
                          ", ".join([g['name']
                                     for g in bundle['relay_groups']])])
    else:
        # a version was specified
        table = [
            ["Bundle ID:", version['bundle_id']],
            ["Version Id:", version['id']],
            ["Name:", version['name']],
            ["Status:", "Enabled" if version['enabled'] else "Disabled"],
            ["Version:", version['version']],
            ["Commands:",
             ", ".join([c['name']
                        for c in version['commands']])],
            ["Permissions:",
             ", ".join([p['bundle'] + ":" + p['name']
                        for p in version['permissions']])]
        ]

    click.echo(cogctl.cli.table.render(table))

import click
from click_didyoumean import DYMGroup
import cogctl
import cogctl.cli.table as tbl
import cogctl.cli.output as output


def validate_user(ctx, param, value):
    """
    Validates the existence of the user by username.
    Returns the user if it exists, thows a BadParameter
    error otherwise.
    """
    output.debug("Fetching the user")
    user = ctx.obj.api.user_by_username(value)
    if user:
        return user
    else:
        raise click.BadParameter("\"%s\" was not found" % value)


@click.group(invoke_without_command=True, cls=DYMGroup)
@click.pass_context
@cogctl.error_handler
def user(ctx):
    """Manage Cog users.

    If invoked without a subcommand, lists all the users on the
    server.
    """
    if ctx.invoked_subcommand is None:
        users = ctx.obj.api.users()
        data = [tx_user(user) for user in users]
        headers = ["username", "full_name", "email_address"]
        table = tbl.render_dicts(data, headers)
        output.echo(table)


@user.command()
@click.option("--first-name",
              help="First name")
@click.option("--last-name",
              help="Last name")
@click.option("--email", prompt="Email",
              help="Email address")
@click.password_option()
@click.argument("username")
@click.pass_obj
@cogctl.error_handler
def create(obj, first_name, last_name, email, username, password):
    """
    Create a new user.
    """
    user = obj.api.new_user({"first_name": first_name,
                             "last_name": last_name,
                             "email_address": email,
                             "username": username,
                             "password": password})

    output.info(render_user(user))


@user.command()
@click.argument("user", callback=validate_user)
@click.pass_obj
@cogctl.error_handler
def info(obj, user):
    """
    Get info about a specific user by username.
    """
    output.echo(render_user(user))


@user.command()
@click.option("--first-name",
              help="First name")
@click.option("--last-name",
              help="Last name")
@click.option("--email",
              help="Email address")
@click.option("--username",
              help="Username")
@click.option("--password",
              help="Password")
@click.argument("user", callback=validate_user)
@click.pass_obj
@cogctl.error_handler
def update(obj, first_name, last_name, email, username, password, user):
    """
    Updates an existing user.
    """
    # Create the updated user object
    attrs = {"first_name": first_name,
             "last_name": last_name,
             "email_address": email,
             "username": username,
             "password": password}

    # Get rid of 'None' values
    attrs = {key: value
             for (key, value) in attrs.items()
             if value is not None}

    # If there are no fields to update exit with an error
    if len(attrs) is 0:
        raise click.UsageError(message="You must specify a field to update.")

    output.debug("Updating '%s' with '%s'" % (user["username"], attrs))

    # Finally update the user
    updated = obj.api.update_user(user["id"], attrs)
    output.info(render_user(updated))


@user.command()
@click.argument("user", callback=validate_user)
@click.confirmation_option(prompt="Are you sure?", is_eager=True)
@click.pass_obj
@cogctl.error_handler
def delete(obj, user):
    """
    Deletes a user.
    """
    obj.api.delete_user(user['id'])
    output.info(render_user(user))


@user.command("password-reset-request")
@click.argument("email")
@click.pass_obj
@cogctl.error_handler
def password_reset_request(obj, email):
    """
    Request a password reset.
    """
    output.info("Requesting password reset")
    obj.api.request_password_reset(email)


@user.command("password-reset")
@click.argument("token")
@click.argument("password")
@click.pass_obj
@cogctl.error_handler
def password_reset(obj, token, password):
    """
    Reset user password with a token.

    A token is received by email after a password reset request.
    """
    output.info("Resetting password")
    obj.api.password_reset(token, password)


def tx_user(user):
    return {"username": user["username"],
            "full_name": "{} {}".format(user.get("first_name") or '',
                                        user.get("last_name") or '').strip(),
            "email_address": user["email_address"]}


def render_user(user):
    data = [["ID", user["id"]],
            ["Username", user["username"]],
            ["Email", user["email_address"]],
            ["First Name", user["first_name"] or ''],
            ["Last Name", user["last_name"] or ''],
            ["Groups", ", ".join(group["name"]
                                 for group in user["groups"])]]

    return tbl.render(data)

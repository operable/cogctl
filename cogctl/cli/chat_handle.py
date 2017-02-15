import click
from click_didyoumean import DYMGroup
import cogctl
import cogctl.api
from cogctl.cli import table


def validate_user(context, param, value):
    """
    Validates the existence of user by username.
    """
    users = context.obj.api.users()
    user = next((u for u in users if u["username"] == value), None)
    if not user:
        raise click.BadParameter("User \"%s\" was not found" % value)

    return user


def validate_chat_provider(context, param, value):
    """
    Validates the existence of chat provider by name
    """
    if value not in ["slack", "hipchat"]:
        raise click.BadParameter("Chat Provider \"%s\" was not found" % value)

    return value


@click.group(invoke_without_command=True, name="chat-handle", cls=DYMGroup)
@click.pass_context
@cogctl.error_handler
def chat_handle(context):
    """
    Manage user chat handles.

    Lists chat handles when called without a subcommand.
    """
    if context.invoked_subcommand is None:
        chat_handles = context.obj.api.chat_handles()
        chat_handles = [chat_handle_tx(chat_handle)
                        for chat_handle in chat_handles]
        output = table.render_dicts(chat_handles,
                                    ["user", "chat_provider", "handle"])
        click.echo(output)


@chat_handle.command()
@click.argument("user", required=True, callback=validate_user)
@click.argument("chat_provider", required=True,
                callback=validate_chat_provider, metavar="CHAT_PROVIDER")
@click.argument("handle", required=True)
@click.pass_obj
@cogctl.error_handler
def create(obj, user, chat_provider, handle):
    "Create a chat handle."
    chat_handle = obj.api.new_chat_handle(user["id"], chat_provider, handle)
    chat_handle = chat_handle_tx(chat_handle)
    output = table.render_dict(chat_handle,
                               ["user", "chat_provider", "handle"])
    click.echo(output)


@chat_handle.command()
@click.argument("user", required=True, callback=validate_user)
@click.argument("chat_provider", required=True,
                callback=validate_chat_provider, metavar="CHAT_PROVIDER")
@click.pass_obj
@cogctl.error_handler
def delete(obj, user, chat_provider):
    "Delete a chat handle."
    chat_handles = obj.api.chat_handles()
    chat_handle = next((ch for ch in chat_handles
                        if ch["user"]["id"] == user["id"] and
                        ch["chat_provider"]["name"] == chat_provider), None)
    if not chat_handle:
        raise click.BadParameter("Chat Handle for User \"%s\" and Chat Provider \"%s\" was not found" % (user["username"], chat_provider)) # noqa

    obj.api.delete_chat_handle(chat_handle["id"])


def chat_handle_tx(chat_handle):
    return {"user": chat_handle["user"]["username"],
            "chat_provider": chat_handle["chat_provider"]["name"],
            "handle": chat_handle["handle"]}

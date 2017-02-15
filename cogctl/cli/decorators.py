import click
import requests
from functools import update_wrapper


def error_handler(f):
    """
    Decorator used for commands to centralize error handling.
    """
    def wrapped(*args, **kwargs):
        try:
            return f(*args, **kwargs)

        except requests.exceptions.ConnectionError as err:
            url = err.request.url
            raise click.ClickException(
                "Could not establish HTTP connection to %s" % url)

        except requests.exceptions.HTTPError as err:
            resp = err.response
            json = resp.json()

            # This is currently due to a fluke in what Cog sends back
            # for invalid credentials
            if (resp.status_code == 403 and
                    'errors' in json and
                    json['errors'] == "invalid credentials"):
                raise click.ClickException("invalid credentials")

            # This is what currently comes back when trying to delete
            # a relay group that has members or assigned bundles.
            #
            # If a relay group has both members and assigned bundles,
            # only the assigned bundles error message is present
            # (since that's what the server checks first).
            if (resp.status_code == 422 and
                    "errors" in json and
                    json["errors"].get("id")):
                raise click.ClickException(" ".join(json["errors"]["id"]))

            raise click.ClickException(" ".join(json["errors"]))

    return update_wrapper(wrapped, f)

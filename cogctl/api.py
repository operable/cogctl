import requests


def from_profile(profile):
    url = profile["url"]
    user = profile["user"]
    password = profile["password"]
    api = Api(url, username=user, password=password)
    return api


class Api:
    def __init__(self, api_root, username=None, password=None):
        self.api_root = api_root
        self.username = username
        self.password = password
        self.api_token = None

    @staticmethod
    def headers(token=None):
        headers = {"accept": "application/json",
                   "content-type": "application/json; charset=utf-8"}
        if token:
            headers['authorization'] = "token %s" % token

        return headers

    def bootstrap_status(self):
        return self.get("/v1/bootstrap", authed=False)

    def bootstrap(self):
        return self.post("/v1/bootstrap", authed=False)

    def commands(self):
        bundles = self.get("/v1/bundles")["bundles"]
        commands = [commands
                    for bundle in bundles
                    for commands in bundle["enabled_version"]["commands"]
                    if bundle["enabled_version"]]
        return commands

    def command_by_name(self, bundle, name):
        commands = self.commands()
        return next((command
                     for command in commands
                     if command["bundle"] == bundle and
                     command["name"] == name), None)

    def token(self):
        if self.api_token:
            return self.api_token
        else:
            r = self.post("/v1/token",
                          data={'username': self.username,
                                'password': self.password},
                          authed=False)

            self.api_token = r['token']['value']
            return self.api_token

    def users(self):
        return self.get("/v1/users")["users"]

    def new_user(self, attrs):
        return self.post("/v1/users", data={"user": attrs})["user"]

    def user(self, id):
        return self.get("/v1/users/%s" % id)["user"]

    def user_by_username(self, username):
        users = self.users()
        return next((user
                     for user in users
                     if user["username"] == username), None)

    def update_user(self, id, attrs):
        return self.put("/v1/users/%s" % id, data={"user": attrs})["user"]

    def delete_user(self, id):
        return self.delete("/v1/users/%s" % id)

    def request_password_reset(self, email):
        return self.post("/v1/users/reset-password",
                         data={"email_address": email})

    def password_reset(self, token, password):
        return self.put("/v1/users/reset-password/%s" % token,
                        data={"password": password})

    def groups(self):
        return self.get("/v1/groups")["groups"]

    def group(self, id):
        return self.get("/v1/groups/" + id)["group"]

    def group_by_name(self, name):
        groups = self.groups()
        return next((group
                     for group in groups
                     if group["name"] == name), None)

    def update_group(self, id, attrs):
        return self.put("/v1/groups/" + id, data={"group": attrs})["group"]

    def new_group(self, name):
        return self.post("/v1/groups",
                         data={"group": {"name": name}})["group"]

    def delete_group(self, id):
        return self.delete("/v1/groups/" + id)

    def add_group_users(self, id, users):
        return self.post("/v1/groups/" + id + "/users",
                         data={"users": {"add": users}})["group"]

    def remove_group_users(self, id, users):
        return self.post("/v1/groups/" + id + "/users",
                         data={"users": {"remove": users}})["group"]

    def grant_group_roles(self, id, roles):
        self.post("/v1/groups/" + id + "/roles",
                  data={"roles": {"add": roles}})
        return self.group(id)

    def revoke_group_roles(self, id, roles):
        self.post("/v1/groups/" + id + "/roles",
                  data={"roles": {"remove": roles}})
        return self.group(id)

    def permissions(self):
        return self.get("/v1/permissions")["permissions"]

    def permission_by_name(self, bundle, name):
        permissions = self.permissions()
        permissions_by_name = (p for p in permissions
                               if p["bundle"] == bundle and
                               p["name"] == name)
        return next(permissions_by_name, None)

    def new_permission(self, name):
        return self.post("/v1/permissions",
                         data={"permission": {"name": name}})["permission"]

    def delete_permission(self, id):
        return self.delete("/v1/permissions/" + id)

    def roles(self):
        return self.get("/v1/roles")["roles"]

    def role_by_name(self, name):
        roles = self.roles()
        roles_by_name = (role for role in roles if role["name"] == name)
        return next(roles_by_name, None)

    def new_role(self, role_name):
        return self.post("/v1/roles",
                         data={"role": {"name": role_name}})["role"]

    def update_role(self, id, attrs):
        return self.put("/v1/roles/" + id, data={"role": attrs})["role"]

    def delete_role(self, id):
        return self.delete("/v1/roles/" + id)

    def new_role_grant(self, id, permission):
        data = {"permissions": {"grant": [permission]}}
        return self.post("/v1/roles/%s/permissions" % id,
                         data=data)["permissions"]

    def delete_role_grant(self, id, permission):
        data = {"permissions": {"revoke": [permission]}}
        return self.post("/v1/roles/%s/permissions" % id,
                         data=data)["permissions"]

    def install_bundle(self, config, force=False):
        return self.post("/v1/bundles",
                         data={'bundle': {
                             'config': config,
                             'force': force}})

    def bundles(self, *names):
        return self._all_or_select("/v1/bundles",
                                   "bundles",
                                   "name", names)

    def bundle(self, name):
        bundle = next((b for b in self.bundles() if b['name'] == name))
        return self.get("/v1/bundles/%s" % bundle["id"])['bundle']

    def bundle_version(self, bundle_id, version_id):
        return self.get(("/v1/bundles/%s/versions/%s" %
                         (bundle_id, version_id)))['bundle_version']

    def install_bundle_from_registry(self, bundle_name, version):
        """
        Set version to "latest" if you want the latest.
        """
        return self.post("/v1/bundles/install/%s/%s" % (bundle_name, version))

    def enable_bundle_version(self, bundle_version):
        return self._bundle_set_status(bundle_version, 'enabled')

    def disable_bundle(self, bundle_version):
        return self._bundle_set_status(bundle_version, 'disabled')

    def _bundle_set_status(self, bundle_version, status):
        bundle_id = bundle_version['bundle_id']
        bv_id = bundle_version['id']
        path = "/v1/bundles/{}/versions/{}/status".format(bundle_id, bv_id)
        return self.post(path, data={'status': status})

    def uninstall_bundle(self, bundle_version):
        bundle_id = bundle_version['bundle_id']
        bv_id = bundle_version['id']
        path = "/v1/bundles/{}/versions/{}".format(bundle_id, bv_id)
        return self.delete(path)

    def bundle_versions(self, bundle):
        path = "/v1/bundles/{}/versions/".format(bundle['id'])
        return self.get(path)['bundle_versions']

    def user_by_name(self, name):
        return self.get("/v1/users", {"username": name})["user"]

    def triggers(self):
        return self.get("/v1/triggers")["triggers"]

    def trigger_by_name(self, name):
        return self.get("/v1/triggers", {"name": name})["triggers"]

    def create_trigger(self, name, pipeline, enable=False, timeout=60,
                       as_user=None, description=None):
        data = {"name": name, "pipeline": pipeline, "enabled": enable,
                "timeout_sec": timeout}
        if as_user is not None:
            data["as_user"] = as_user
        if description is not None:
            data["description"] = description
        return self.post("/v1/triggers", {"trigger": data})["trigger"]

    def delete_trigger(self, id):
        return self.delete("/v1/triggers/%s" % id)

    def update_trigger(self, id, data):
        return self.put("/v1/triggers/%s" % id, {"trigger": data})["trigger"]

    def chat_handles(self):
        return self.get("/v1/chat_handles")["chat_handles"]

    def new_chat_handle(self, user_id, chat_provider, handle):
        return self.post("/v1/users/%s/chat_handles" % user_id,
                         data={"chat_handle": {
                                   "chat_provider": chat_provider,
                                   "handle": handle}})["chat_handle"]

    def delete_chat_handle(self, id):
        return self.delete("/v1/chat_handles/" + id)

    def relays(self, *names):
        return self._all_or_select("/v1/relays", "relays", "name", names)

    def relay_groups(self, *names):
        return self._all_or_select("/v1/relay_groups",
                                   "relay_groups",
                                   "name", names)

    def create_relay_group(self, name):
        return self.post("/v1/relay_groups",
                         data={"relay_group":
                               {"name": name}})["relay_group"]

    def delete_relay_group(self, group):
        return self.delete("/v1/relay_groups/{}".format(group["id"]))

    def _modify_relay_association(self, group, kind, op, items):
        if kind not in ("relays", "bundles"):
            raise Exception(
                "'{}' is not a valid value for 'kind' argument".format(kind))

        if op not in ("add", "remove"):
            raise Exception(
                "'{}' is not a valid value for 'op' argument".format(op))

        r = self.post("/v1/relay_groups/{}/{}".format(group["id"], kind),
                      data={kind: {op: [i["id"] for i in items]}})

        return r["relay_group"]

    def add_relays_to_group(self, group, relays):
        return self._modify_relay_association(group, "relays", "add", relays)

    def remove_relays_from_group(self, group, relays):
        return self._modify_relay_association(group, "relays",
                                              "remove", relays)

    def assign_bundles_to_group(self, group, bundles):
        return self._modify_relay_association(group, "bundles", "add", bundles)

    def unassign_bundles_from_group(self, group, bundles):
        return self._modify_relay_association(group, "bundles",
                                              "remove", bundles)

    def relay(self, relay_id):
        return self.get("/v1/relays/%s" % relay_id)["relay"]

    def new_relay(self, name, relay_id, token, description="", enabled=False,
                  relay_groups=[]):
        relay = self.post("/v1/relays",
                          data={"relay": {
                                    "name": name,
                                    "id": relay_id,
                                    "token": token,
                                    "description": description,
                                    "enabled": enabled}})["relay"]
        for group in relay_groups:
            self.add_relays_to_group(group, [relay])

        return self.relay(relay["id"])

    def update_relay(self, relay_id, attrs):
        return self.put("/v1/relays/%s" % relay_id,
                        data={"relay": attrs})["relay"]

    def set_relay_status(self, relay_id, status):
        enabled = status == "enabled"
        return self.put("/v1/relays/%s" % relay_id,
                        data={"relay": {"enabled": enabled}})["relay"]

    def delete_relay(self, relay_id):
        return self.delete("/v1/relays/%s" % relay_id)

    ########################################################################

    def rules_for_command(self, command):
        command_name = command["bundle"] + ":" + command["name"]
        response = self.get("/v1/rules", params={"for-command": command_name})
        return response["rules"]

    def rule(self, id):
        return self.get("/v1/rules/" + id)

    def new_rule(self, rule):
        return self.post("/v1/rules", {"rule": rule})

    def delete_rule(self, id):
        return self.delete("/v1/rules/" + id)

    @staticmethod
    def dynamic_config_layer_path(bundle, layer, name):
        if layer == "base":
            path = "/v1/bundles/{}/dynamic_config/{}".format(
                bundle['id'], layer)
        else:
            path = "/v1/bundles/{}/dynamic_config/{}/{}".format(
                bundle['id'], layer, name)

        return path

    def create_config_layer(self, bundle, layer, name, config):
        return self.post(Api.dynamic_config_layer_path(bundle, layer, name),
                         data={"config": config})['dynamic_configuration']

    def dynamic_configs(self, bundle):
        path = "/v1/bundles/{}/dynamic_config".format(bundle['id'])
        return self.get(path)['dynamic_configurations']

    def dynamic_config(self, bundle, layer, name):
        configs = self.dynamic_configs(bundle)

        # "config" is the "name" of the single base layer, by convention
        if layer == "base":
            name = "config"

        return next((c for c in configs
                     if (c['layer'] == layer and
                         c['name'] == name)))

    def delete_dynamic_config(self, bundle, layer, name):
        return self.delete(Api.dynamic_config_layer_path(bundle, layer, name))

    ########################################################################

    def _all_or_select(self, path, key, filter_key, filter_values):
        """Either return all values, or select values by key.

        Use this to e.g., either return all bundles, or all bundles
        whose "name" is within a given list of values.

        This should only be used if you need "partial" objects; for
        instance, the data returned for a bundle from the /v1/bundles
        resource, and not from /v1/bundles/$BUNDLE_ID.

        """
        all_values = self.get(path)[key]
        if filter_values:
            return [v for v in all_values if v[filter_key] in filter_values]
        else:
            return all_values

    ########################################################################

    def get(self, path, params={}, authed=True):
        if authed:
            headers = Api.headers(self.token())
        else:
            headers = Api.headers()
        r = requests.get("%s%s" % (self.api_root, path), params=params,
                         headers=headers)

        r.raise_for_status()

        return r.json()

    def post(self, path, data={}, authed=True):
        if authed:
            headers = Api.headers(self.token())
        else:
            headers = Api.headers()

        r = requests.post("%s%s" % (self.api_root, path),
                          headers=headers,
                          json=data)

        r.raise_for_status()

        # NOTE: We get a 204 back when POSTing to 'users/reset-password' to
        # request a password reset. So we check for that and just return
        # an empty dict instead of crashing when r.json() is called.
        if r.status_code == 204:
            return {}
        else:
            return r.json()

    def put(self, path, data={}, authed=True):
        if authed:
            headers = Api.headers(self.token())
        else:
            headers = Api.headers()

        r = requests.put("%s%s" % (self.api_root, path),
                         headers=headers,
                         json=data)

        r.raise_for_status()

        # NOTE: Similar to POSTing to 'users/reset-password' making a PUT
        # request to 'users/reset-password/<id>' results in a 204. We check
        # for that and return an empty dict if that be case.
        if r.status_code == 204:
            return {}
        else:
            return r.json()

    def delete(self, path, authed=True):
        if authed:
            headers = Api.headers(self.token())
        else:
            headers = Api.headers()

        r = requests.delete("%s%s" % (self.api_root, path),
                            headers=headers)

        r.raise_for_status()

        return r

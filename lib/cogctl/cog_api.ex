defmodule Cogctl.CogApi do

  defstruct [proto: "http", host: nil, port: nil, version: 1, token: nil, username: nil,
             password: nil]

  def new_client(profile=%Cogctl.Profile{}) do
    proto = if profile.secure == true do
      "https"
    else
      "http"
    end
    %__MODULE__{proto: proto, host: profile.host, port: profile.port, username: profile.user,
                password: profile.password}
  end

  def authenticate(%__MODULE__{token: nil}=api) do
    rescue_econnrefused(fn ->
      response = HTTPotion.post(make_url(api, "token", [username: api.username,
                                                        password: api.password]),
                                headers: make_headers(api, ["Accept": "application/json"]))
      body = Poison.decode!(response.body)
      case HTTPotion.Response.success?(response) do
        true ->
          token = get_in(body, ["token", "value"])
          {:ok, %{api | token: token}}
        false ->
          {:error, body}
      end
    end)
  end
  def authenticate(%__MODULE__{}=api) do
    {:ok, api}
  end

  def get(%__MODULE__{}=api, resource, params \\ []) do
    rescue_econnrefused(fn ->
      response = HTTPotion.get(make_url(api, resource, params), headers: make_headers(api))
      {response_type(response), Poison.decode!(response.body)}
    end)
  end

  def post(%__MODULE__{}=api, resource, params) do
    rescue_econnrefused(fn ->
      body = Poison.encode!(params)
      response = HTTPotion.post(make_url(api, resource), body: body, headers: make_headers(api, ["Content-Type": "application/json"]))
      {response_type(response), Poison.decode!(response.body)}
    end)
  end

  def patch(%__MODULE__{}=api, resource, params) do
    rescue_econnrefused(fn ->
      body = Poison.encode!(params)
      response = HTTPotion.patch(make_url(api, resource), body: body, headers: make_headers(api, ["Content-Type": "application/json"]))
      {response_type(response), Poison.decode!(response.body)}
    end)
  end

  def delete(%__MODULE__{}=api, resource) do
    rescue_econnrefused(fn ->
      response = HTTPotion.delete(make_url(api, resource), headers: make_headers(api))
      case response_type(response) do
        :ok ->
          :ok
        :error ->
          {:error, Poison.decode!(response.body)}
      end
    end)
  end

  # TODO: Replace the following with single parameterized get call once it
  # exists in the Cog API
  def get_by(%__MODULE__{}=api, resource, filter) do
    with {:ok, id} <- find_id_by(api, resource, filter) do
      get(api, resource <> "/" <> URI.encode(id))
    end
  end

  def patch_by(%__MODULE__{}=api, resource, filter, params) do
    with {:ok, id} <- find_id_by(api, resource, filter) do
      patch(api, resource <> "/" <> URI.encode(id), params)
    end
  end

  def delete_by(%__MODULE__{}=api, resource, filter) do
    with {:ok, id} <- find_id_by(api, resource, filter) do
      delete(api, resource <> "/" <> URI.encode(id))
    end
  end

  def find_id_by(api, resource, find_fun)
      when is_function(find_fun) do
    with {:ok, %{^resource => items}} <- get(api, resource) do
      case Enum.find(items, find_fun) do
        %{"id" => id} ->
          {:ok, id}
        nil ->
          {:error, %{"error" => "Resource not found"}}
      end
    end
  end

  def find_id_by(api, resource, [{param_key, param_value}]) do
    find_id_by(api, resource, fn item ->
      item[to_string(param_key)] == param_value
    end)
  end

  def bootstrap_show(%__MODULE__{}=api) do
    get(api, "bootstrap")
  end

  def bootstrap_create(%__MODULE__{}=api) do
    post(api, "bootstrap", [])
  end

  def bundle_index(%__MODULE__{}=api) do
    get(api, "bundles")
  end

  def bundle_show(%__MODULE__{}=api, bundle_name) do
    get_by(api, "bundles", name: bundle_name)
  end

  def bundle_delete(%__MODULE__{}=api, bundle_name) do
    delete_by(api, "bundles", name: bundle_name)
  end

  def bundle_status(%__MODULE__{}=api, bundle_name, status) do
    with {:ok, bundle_id} <- find_id_by(api, "bundles", name: bundle_name) do
      post(api, "bundles/#{bundle_id}/status", %{status: status})
    end
  end

  def bundle_enable(%__MODULE__{}=api, bundle_name) do
    bundle_status(api, bundle_name, "enabled")
  end

  def bundle_disable(%__MODULE__{}=api, bundle_name) do
    bundle_status(api, bundle_name, "disabled")
  end

  def user_index(%__MODULE__{}=api) do
    get(api, "users")
  end

  def user_show(%__MODULE__{}=api, user_username) do
    get_by(api, "users", username: user_username)
  end

  def user_create(%__MODULE__{}=api, params) do
    post(api, "users", params)
  end

  def user_update(%__MODULE__{}=api, user_username, params) do
    patch_by(api, "users", [username: user_username], params)
  end

  def user_delete(%__MODULE__{}=api, user_username) do
    delete_by(api, "users", username: user_username)
  end

  def group_index(%__MODULE__{}=api) do
    get(api, "groups")
  end

  def group_show(%__MODULE__{}=api, group_name) do
    with {:ok, group_id} <- find_id_by(api, "groups", name: group_name),
      {:ok, group} <- get(api, "groups/#{URI.encode(group_id)}"),
      {:ok, members} <- get(api, "groups/#{URI.encode(group_id)}/memberships"),
      do: {:ok, Map.update!(group, "group", &Map.merge(&1, members))}
  end

  def group_create(%__MODULE__{}=api, params) do
    post(api, "groups", params)
  end

  def group_update(%__MODULE__{}=api, group_name, params) do
    patch_by(api, "groups", [name: group_name], params)
  end

  def group_delete(%__MODULE__{}=api, group_name) do
    delete_by(api, "groups", name: group_name)
  end

  def group_add(%__MODULE__{}=api, group_name, type, item_to_add)
      when type in [:users, :groups] do
    with {:ok, group_id} <- find_id_by(api, "groups", name: group_name),
      {:ok, group} <- get(api, "groups/#{URI.encode(group_id)}"),
      {:ok, _} <- post(api, "groups/#{URI.encode(group_id)}/membership", %{members: Map.put(%{}, type, %{add: [item_to_add]})}),
      {:ok, members} <- get(api, "groups/#{URI.encode(group_id)}/memberships"),
      do: {:ok, Map.update!(group, "group", &Map.merge(&1, members))}
  end

  def group_remove(%__MODULE__{}=api, group_name, type, item_to_remove)
      when type in [:users, :groups] do
    with {:ok, group_id} <- find_id_by(api, "groups", name: group_name),
      {:ok, group} <- get(api, "groups/#{URI.encode(group_id)}"),
      {:ok, _} <- post(api, "groups/#{URI.encode(group_id)}/membership", %{members: Map.put(%{}, type, %{remove: [item_to_remove]})}),
      {:ok, members} <- get(api, "groups/#{URI.encode(group_id)}/memberships"),
      do: {:ok, Map.update!(group, "group", &Map.merge(&1, members))}
  end

  def role_index(%__MODULE__{}=api) do
    get(api, "roles")
  end

  def role_create(%__MODULE__{}=api, params) do
    post(api, "roles", params)
  end

  def role_update(%__MODULE__{}=api, role_name, params) do
    patch_by(api, "roles", [name: role_name], params)
  end

  def role_delete(%__MODULE__{}=api, role_name) do
    delete_by(api, "roles", name: role_name)
  end

  def role_grant(%__MODULE__{}=api, role_name, type, item_to_grant)
      when type in ["users", "groups"] do
    result = case type do
      "users" ->
        find_id_by(api, type, username: item_to_grant)
      "groups" ->
        find_id_by(api, type, name: item_to_grant)
    end

    with {:ok, id} <- result do
      post(api, "#{type}/#{URI.encode(id)}/roles", %{roles: %{grant: [role_name]}})
    end
  end

  def role_revoke(%__MODULE__{}=api, role_name, type, item_to_revoke)
      when type in ["users", "groups"] do
    result = case type do
      "users" ->
        find_id_by(api, type, username: item_to_revoke)
      "groups" ->
        find_id_by(api, type, name: item_to_revoke)
    end

    with {:ok, id} <- result do
      post(api, "#{type}/#{URI.encode(id)}/roles", %{roles: %{revoke: [role_name]}})
    end
  end

  def permission_index(api, params \\ [])

  def permission_index(%__MODULE__{}=api, [user: user_username]) do
    with {:ok, user_id} <- find_id_by(api, "users", username: user_username) do
      get(api, "users/#{user_id}/permissions")
    end
  end

  def permission_index(%__MODULE__{}=api, [group: group_name]) do
    with {:ok, group_id} <- find_id_by(api, "groups", name: group_name) do
      get(api, "groups/#{group_id}/permissions")
    end
  end

  def permission_index(%__MODULE__{}=api, params) do
    get(api, "permissions", params)
  end

  def permission_create(%__MODULE__{}=api, params) do
    post(api, "permissions", params)
  end

  def permission_delete(%__MODULE__{}=api, name) do
    delete_by(api, "permissions", fn item ->
      item["name"] == name &&
        item["namespace"]["name"] == "site"
    end)
  end

  def permission_grant(%__MODULE__{}=api, permission_name, type, item_to_grant)
      when type in ["users", "roles", "groups"] do
    result = case type do
      "users" ->
        find_id_by(api, type, username: item_to_grant)
      type when type in ["roles", "groups"] ->
        find_id_by(api, type, name: item_to_grant)
    end

    with {:ok, id} <- result do
      post(api, "#{type}/#{URI.encode(id)}/permissions", %{permissions: %{grant: [permission_name]}})
    end
  end

  def permission_revoke(%__MODULE__{}=api, permission_name, type, item_to_revoke)
      when type in ["users", "roles", "groups"] do
    result = case type do
      "users" ->
        find_id_by(api, type, username: item_to_revoke)
      type when type in ["roles", "groups"] ->
        find_id_by(api, type, name: item_to_revoke)
    end

    with {:ok, id} <- result do
      post(api, "#{type}/#{URI.encode(id)}/permissions", %{permissions: %{revoke: [permission_name]}})
    end
  end

  def rule_index(%__MODULE__{}=api, command) do
    get(api, "rules?for-command=" <> URI.encode(command))
  end

  def rule_create(%__MODULE__{}=api, params) do
    post(api, "rules", params)
  end

  def rule_delete(%__MODULE__{}=api, rule_id) do
    delete(api, "rules" <> "/" <> URI.encode(rule_id))
  end

  def chat_handle_index(%__MODULE__{}=api) do
    get(api, "chat_handles")
  end

  def chat_handle_create(%__MODULE__{}=api, %{chat_handle: %{user: user}} = params) do
    with {:ok, user_id} <- find_id_by(api, "users", username: user) do
      post(api, "users/#{user_id}/chat_handles", params)
    end
  end

  def chat_handle_delete(%__MODULE__{}=api, %{chat_handle: %{user: user, chat_provider: chat_provider}}) do
    delete_by(api, "chat_handles", fn item ->
      item["user"]["username"] == user &&
        item["chat_provider"]["name"] == chat_provider
    end)
  end

  defp rescue_econnrefused(fun) do
    try do
      fun.()
    rescue
      HTTPotion.HTTPError ->
        {:error, %{"error" => "An instance of cog must be running"}}
    end
  end

  defp make_url(%__MODULE__{proto: proto, host: host, port: port,
                            version: version}, route, params \\ []) do
    route = if is_function(route) do
      route.()
    else
      route
    end
    url = "#{proto}://#{host}:#{port}/v#{version}"
    url = if String.starts_with?(route, "/") do
      "#{url}#{route}"
    else
      "#{url}/#{route}"
    end
    if length(params) == 0 do
      url
    else
      URI.encode(url <> "?" <> URI.encode_query(params))
    end
  end

  defp make_headers(api, others \\ ["Accept": "application/json"])

  defp make_headers(%__MODULE__{token: nil}, others) do
    others
  end
  defp make_headers(%__MODULE__{token: token}, others) do
    ["authorization": "token " <> token] ++ others
  end

  defp response_type(response) do
    if HTTPotion.Response.success?(response) do
      :ok
    else
      :error
    end
  end

end

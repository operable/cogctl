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
  end
  def authenticate(%__MODULE__{}=api) do
    {:ok, api}
  end

  def is_bootstrapped?(%__MODULE__{}=api) do
    response = HTTPotion.get(make_url(api, "bootstrap"), headers: make_headers(api))
    {response_type(response), Poison.decode!(response.body)}
  end

  def get(%__MODULE__{}=api, resource, params \\ []) do
    response = HTTPotion.get(make_url(api, resource, params), headers: make_headers(api))
    {response_type(response), Poison.decode!(response.body)}
  end

  def post(%__MODULE__{}=api, resource, params) do
    body = Poison.encode!(params)
    response = HTTPotion.post(make_url(api, resource), body: body, headers: make_headers(api, ["Content-Type": "application/json"]))
    {response_type(response), Poison.decode!(response.body)}
  end

  def patch(%__MODULE__{}=api, resource, params) do
    body = Poison.encode!(params)
    response = HTTPotion.patch(make_url(api, resource), body: body, headers: make_headers(api, ["Content-Type": "application/json"]))
    {response_type(response), Poison.decode!(response.body)}
  end

  def delete(%__MODULE__{}=api, resource) do
    response = HTTPotion.delete(make_url(api, resource), headers: make_headers(api))
    case response_type(response) do
      :ok ->
        :ok
      :error ->
        {:error, Poison.decode!(response.body)}
    end
  end

  # TODO: Replace the following with single parameterized get call once it
  # exists in the Cog API
  def get_by(%__MODULE__{}=api, resource, filter) do
    id = find_id_by(api, resource, filter)
    get(api, resource <> "/" <> URI.encode(id))
  end

  def patch_by(%__MODULE__{}=api, resource, filter, params) do
    id = find_id_by(api, resource, filter)
    patch(api, resource <> "/" <> URI.encode(id), params)
  end

  def delete_by(%__MODULE__{}=api, resource, filter) do
    id = find_id_by(api, resource, filter)
    delete(api, resource <> "/" <> URI.encode(id))
  end

  def find_id_by(api, resource, find_fun)
      when is_function(find_fun) do
    {:ok, %{^resource => items}} = get(api, resource)

    case Enum.find(items, find_fun) do
      %{"id" => id} ->
        id
      nil ->
        nil
    end
  end

  def find_id_by(api, resource, [{param_key, param_value}]) do
    find_id_by(api, resource, fn item ->
      item[to_string(param_key)] == param_value
    end)
  end

  def bootstrap(%__MODULE__{}=api) do
    response = HTTPotion.post(make_url(api, "bootstrap"))
    {response_type(response), Poison.decode!(response.body)}
  end

  def bundle_index(%__MODULE__{}=api) do
    get(api, "bundles")
  end

  def bundle_show(%__MODULE__{}=api, bundle_name) do
    get_by(api, "bundles", name: bundle_name)
  end

  def bundle_delete(%__MODULE__{}=api, bundle_id) do
    response = HTTPotion.delete(make_url(api, fn -> "bundles/" <> URI.encode(bundle_id) end),
                                headers: make_headers(api))
    response_type(response)
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
    group_id = find_id_by(api, "groups", name: group_name)
    {:ok, group} = get(api, "groups/#{URI.encode(group_id)}")
    {:ok, members} = get(api, "groups/#{URI.encode(group_id)}/memberships")
    {:ok, Map.update!(group, "group", &Map.merge(&1, members))}
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
    group_id = find_id_by(api, "groups", name: group_name)
    {:ok, group} = get(api, "groups/#{URI.encode(group_id)}")
    post(api, "groups/#{URI.encode(group_id)}/membership", %{members: Map.put(%{}, type, %{add: [item_to_add]})})
    {:ok, members} = get(api, "groups/#{URI.encode(group_id)}/memberships")
    {:ok, Map.update!(group, "group", &Map.merge(&1, members))}
  end

  def group_remove(%__MODULE__{}=api, group_name, type, item_to_remove)
      when type in [:users, :groups] do
    group_id = find_id_by(api, "groups", name: group_name)
    {:ok, group} = get(api, "groups/#{URI.encode(group_id)}")
    post(api, "groups/#{URI.encode(group_id)}/membership", %{members: Map.put(%{}, type, %{remove: [item_to_remove]})})
    {:ok, members} = get(api, "groups/#{URI.encode(group_id)}/memberships")
    {:ok, Map.update!(group, "group", &Map.merge(&1, members))}
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
    id = case type do
      "users" ->
        find_id_by(api, type, username: item_to_grant)
      "groups" ->
        find_id_by(api, type, name: item_to_grant)
    end

    post(api, "#{type}/#{URI.encode(id)}/roles", %{roles: %{grant: [role_name]}})
  end

  def role_revoke(%__MODULE__{}=api, role_name, type, item_to_revoke)
      when type in ["users", "groups"] do
    id = case type do
      "users" ->
        find_id_by(api, type, username: item_to_revoke)
      "groups" ->
        find_id_by(api, type, name: item_to_revoke)
    end

    post(api, "#{type}/#{URI.encode(id)}/roles", %{roles: %{revoke: [role_name]}})
  end

  def permission_index(api, params \\ [])

  def permission_index(%__MODULE__{}=api, [user: user_username]) do
    user_id = find_id_by(api, "users", username: user_username)
    get(api, "users/#{user_id}/permissions")
  end

  def permission_index(%__MODULE__{}=api, [group: group_name]) do
    group_id = find_id_by(api, "groups", name: group_name)
    get(api, "groups/#{group_id}/permissions")
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
    id = case type do
      "users" ->
        find_id_by(api, type, username: item_to_grant)
      type when type in ["roles", "groups"] ->
        find_id_by(api, type, name: item_to_grant)
    end

    post(api, "#{type}/#{URI.encode(id)}/permissions", %{permissions: %{grant: [permission_name]}})
  end

  def permission_revoke(%__MODULE__{}=api, permission_name, type, item_to_revoke)
      when type in ["users", "roles", "groups"] do
    id = case type do
      "users" ->
        find_id_by(api, type, username: item_to_revoke)
      type when type in ["roles", "groups"] ->
        find_id_by(api, type, name: item_to_revoke)
    end

    post(api, "#{type}/#{URI.encode(id)}/permissions", %{permissions: %{revoke: [permission_name]}})
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

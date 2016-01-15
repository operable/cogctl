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

  def get(%__MODULE__{}=api, resource) do
    response = HTTPotion.get(make_url(api, resource), headers: make_headers(api))
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

  def bootstrap(%__MODULE__{}=api) do
    response = HTTPotion.post(make_url(api, "bootstrap"))
    {response_type(response), Poison.decode!(response.body)}
  end

  def bundle_index(%__MODULE__{}=api) do
    get(api, "bundles")
  end

  def bundle_show(%__MODULE__{}=api, bundle_name) do
    {:ok, %{"bundles" => bundles}} = get(api, "bundles")

    %{"id" => bundle_id} = Enum.find(bundles, fn bundle ->
      bundle["name"] == bundle_name
    end)

    get(api, "bundles/#{URI.encode(bundle_id)}")
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
    {:ok, %{"users" => users}} = get(api, "users")

    %{"id" => user_id} = Enum.find(users, fn user ->
      user["username"] == user_username
    end)

    get(api, "users/#{URI.encode(user_id)}")
  end

  def user_create(%__MODULE__{}=api, params) do
    post(api, "users", params)
  end

  def user_update(%__MODULE__{}=api, user_username, params) do
    {:ok, %{"users" => users}} = get(api, "users")

    %{"id" => user_id} = Enum.find(users, fn user ->
      user["username"] == user_username
    end)

    patch(api, "users/#{URI.encode(user_id)}", params)
  end

  def user_delete(%__MODULE__{}=api, user_username) do
    {:ok, %{"users" => users}} = get(api, "users")

    %{"id" => user_id} = Enum.find(users, fn user ->
      user["username"] == user_username
    end)

    delete(api, "users/#{URI.encode(user_id)}")
  end

  def group_index(%__MODULE__{}=api) do
    get(api, "groups")
  end

  def group_create(%__MODULE__{}=api, params) do
    post(api, "groups", params)
  end

  def group_update(%__MODULE__{}=api, group_name, params) do
    {:ok, %{"groups" => groups}} = get(api, "groups")

    %{"id" => group_id} = Enum.find(groups, fn group ->
      group["name"] == group_name
    end)

    patch(api, "groups/#{URI.encode(group_id)}", params)
  end

  def group_delete(%__MODULE__{}=api, group_name) do
    {:ok, %{"groups" => groups}} = get(api, "groups")

    %{"id" => group_id} = Enum.find(groups, fn group ->
      group["name"] == group_name
    end)

    delete(api, "groups/#{URI.encode(group_id)}")
  end

  def role_index(%__MODULE__{}=api) do
    get(api, "roles")
  end

  def role_create(%__MODULE__{}=api, params) do
    post(api, "roles", params)
  end

  def role_update(%__MODULE__{}=api, role_name, params) do
    {:ok, %{"roles" => roles}} = get(api, "roles")

    %{"id" => role_id} = Enum.find(roles, fn role ->
      role["name"] == role_name
    end)

    patch(api, "roles/#{URI.encode(role_id)}", params)
  end

  def role_delete(%__MODULE__{}=api, role_name) do
    {:ok, %{"roles" => roles}} = get(api, "roles")

    %{"id" => role_id} = Enum.find(roles, fn role ->
      role["name"] == role_name
    end)

    delete(api, "roles/#{URI.encode(role_id)}")
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

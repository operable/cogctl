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

  def bootstrap(%__MODULE__{}=api) do
    response = HTTPotion.post(make_url(api, "bootstrap"))
    {response_type(response), Poison.decode!(response.body)}
  end

  def list_all_bundles(%__MODULE__{}=api) do
    response = HTTPotion.get(make_url(api, "bundles"),
                             headers: make_headers(api))
    {response_type(response), Poison.decode!(response.body)}
  end

  def bundle_info(%__MODULE__{}=api, bundle_id) do
    response = HTTPotion.get(make_url(api, fn -> "bundles/" <> URI.encode(bundle_id) end),
                             headers: make_headers(api))
    {response_type(response), Poison.decode!(response.body)}
  end

  def bundle_delete(%__MODULE__{}=api, bundle_id) do
    response = HTTPotion.delete(make_url(api, fn -> "bundles/" <> URI.encode(bundle_id) end),
                                headers: make_headers(api))
    response_type(response)
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

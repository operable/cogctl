defmodule Cogctl.CogApi do

  defstruct [proto: "http", host: nil, port: nil, version: 1]

  def new_client(profile=%Cogctl.Profile{}) do
    proto = if profile.secure == true do
      "https"
    else
      "http"
    end
    %__MODULE__{proto: proto, host: profile.host, port: profile.port}
  end

  def is_bootstrapped?(%__MODULE__{}=api) do
    response = HTTPotion.get(make_url(api, "bootstrap"))
    if HTTPotion.Response.success?(response) do
      {:ok, Poison.decode!(response.body)}
    else
      {:error, Poison.decode!(response.body)}
    end
  end

  def bootstrap(%__MODULE__{}=api) do
    response = HTTPotion.post(make_url(api, "bootstrap"))
    if HTTPotion.Response.success?(response) do
      {:ok, Poison.decode!(response.body)}
    else
      {:error, Poison.decode!(response.body)}
    end
  end

  defp make_url(%__MODULE__{proto: proto, host: host, port: port,
                          version: version}, route) do
    url = "#{proto}://#{host}:#{port}/v#{version}"
    if String.starts_with?(route, "/") do
      "#{url}#{route}"
    else
      "#{url}/#{route}"
    end
  end

end

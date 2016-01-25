defmodule Cogctl.Actions.Permissions.Create do
  use Cogctl.Action, "permissions create"
  alias Cogctl.CogApi

  def option_spec do
    [{:name, :undefined, :undefined, {:string, :undefined}, 'Permission name'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_create(client, :proplists.get_value(:name, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_create(client, "site:" <> name) do
    case CogApi.permission_create(client, %{permission: %{name: name}}) do
      {:ok, _resp} ->
        IO.puts("Created site:#{name}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp do_create(_client, _name) do
    {:error, "Permissions must be created under the site namespace"}
  end
end

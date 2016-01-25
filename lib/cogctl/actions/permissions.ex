defmodule Cogctl.Actions.Permissions do
  use Cogctl.Action, "permissions"
  alias Cogctl.CogApi
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_list(client)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_list(client) do
    case CogApi.permission_index(client) do
      {:ok, resp} ->
        permissions = resp["permissions"]
        permission_attrs = for permission <- permissions do
          [permission["name"], permission["id"]]
        end

        IO.puts(Table.format([["NAME", "ID"]] ++ permission_attrs))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

defmodule Cogctl.Actions.Roles do
  use Cogctl.Action, "roles"
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

  def do_list(client) do
    case CogApi.role_index(client) do
      {:ok, resp} ->
        roles = resp["roles"]
        role_attrs = for role <- roles do
          [role["name"], role["id"]]
        end

        IO.puts(Table.format([["NAME", "ID"]] ++ role_attrs))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

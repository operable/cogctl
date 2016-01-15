defmodule Cogctl.Actions.Users do
  use Cogctl.Action, "users"
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
    case CogApi.user_index(client) do
      {:ok, resp} ->
        users = resp["users"]
        user_attrs = for user <- users do
          [user["username"], user["first_name"] <> " " <> user["last_name"]]
        end

        IO.puts(Table.format([["USERNAME", "FULL NAME"]] ++ user_attrs))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

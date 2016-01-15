defmodule Cogctl.Actions.Role.List do
  use Cogctl.Action, "role list"
  alias Cogctl.CogApi

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
    case CogApi.role_list(client) do
      {:ok, resp} ->
        roles = resp["roles"]
        for role <- roles do
          id = role["id"]
          name = role["name"]
          IO.puts "Role: #{name} (#{id})"
        end
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

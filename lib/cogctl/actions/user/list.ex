defmodule Cogctl.Actions.User.List do
  use Cogctl.Action, "user list"
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
    case CogApi.user_list(client) do
      {:ok, resp} ->
        users = resp["users"]
        for user <- users do
          id = user["id"]
          first_name = user["first_name"]
          last_name = user["last_name"]
          IO.puts "User: #{first_name} #{last_name} (#{id})"
        end
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

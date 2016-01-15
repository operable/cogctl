defmodule Cogctl.Actions.Users.Delete do
  use Cogctl.Action, "users delete"
  alias Cogctl.CogApi

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'Username'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, :proplists.get_value(:user, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  def do_delete(client, user_username) do
    case CogApi.user_delete(client, user_username) do
      :ok ->
        IO.puts("Deleted #{user_username}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

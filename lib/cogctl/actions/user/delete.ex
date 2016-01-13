defmodule Cogctl.Actions.User.Delete do
  use Cogctl.Action, "user delete"
  alias Cogctl.CogApi

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'User id'}]
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

  def do_delete(client, user_id) do
    case CogApi.user_delete(client, user_id) do
      :ok ->
        IO.puts "Deleted user: #{user_id}"
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

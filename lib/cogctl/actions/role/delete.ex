defmodule Cogctl.Actions.Role.Delete do
  use Cogctl.Action, "role delete"
  alias Cogctl.CogApi

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role id'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, :proplists.get_value(:role, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  def do_delete(client, role_id) do
    case CogApi.role_delete(client, role_id) do
      :ok ->
        IO.puts "Deleted role: #{role_id}"
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

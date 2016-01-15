defmodule Cogctl.Actions.Permissions.Delete do
  use Cogctl.Action, "permissions delete"
  alias Cogctl.CogApi

  def option_spec do
    [{:permission, :undefined, :undefined, {:string, :undefined}, 'Permission name'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, :proplists.get_value(:permission, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_delete(client, permission_name) do
    case CogApi.permission_delete(client, permission_name) do
      :ok ->
        IO.puts "Deleted #{permission_name}"
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

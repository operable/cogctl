defmodule Cogctl.Actions.Roles.Delete do
  use Cogctl.Action, "roles delete"
  alias Cogctl.CogApi

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role name (required)'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, :proplists.get_value(:role, options))
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_delete(_client, :undefined) do
    display_arguments_error
  end

  defp do_delete(client, role_name) do
    case CogApi.role_delete(client, role_name) do
      :ok ->
        display_output("Deleted #{role_name}")
      {:error, error} ->
        display_error(error["error"])
    end
  end
end

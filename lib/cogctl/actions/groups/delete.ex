defmodule Cogctl.Actions.Groups.Delete do
  use Cogctl.Action, "groups delete"
  alias Cogctl.CogApi

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, :proplists.get_value(:group, options))
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_delete(_client, :undefined) do
    display_arguments_error
  end

  defp do_delete(client, group_name) do
    case CogApi.group_delete(client, group_name) do
      :ok ->
        display_output("Deleted #{group_name}")
      {:error, error} ->
        display_error(error["error"])
    end
  end
end

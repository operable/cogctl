defmodule Cogctl.Actions.Groups.Delete do
  use Cogctl.Action, "groups delete"

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, client) do
    with_authentication(client,
                        &do_delete(&1, :proplists.get_value(:group, options)))
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

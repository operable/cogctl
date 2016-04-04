defmodule Cogctl.Actions.Groups.Delete do
  use Cogctl.Action, "groups delete"

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    with_authentication(endpoint,
                        &do_delete(&1, :proplists.get_value(:group, options)))
  end

  defp do_delete(_endpoint, :undefined) do
    display_arguments_error
  end

  defp do_delete(endpoint, group_name) do
    case CogApi.HTTP.Internal.group_delete(endpoint, group_name) do
      :ok ->
        display_output("Deleted #{group_name}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

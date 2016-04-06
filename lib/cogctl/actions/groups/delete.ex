defmodule Cogctl.Actions.Groups.Delete do
  use Cogctl.Action, "groups delete"

  alias Cogctl.Actions.Groups
  alias CogApi.HTTP.Client

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    group = Groups.find_by_name(endpoint, :proplists.get_value(:group, options))
    do_delete(endpoint, group)
  end

  defp do_delete(_endpoint, :undefined), do: display_arguments_error
  defp do_delete(endpoint, group) do
    case Client.group_delete(endpoint, group.id) do
      :ok ->
        display_output("Deleted #{group.name}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

end

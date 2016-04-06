defmodule Cogctl.Actions.Groups.Delete do
  use Cogctl.Action, "groups delete"

  alias CogApi.HTTP.Client

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    group_name = :proplists.get_value(:group, options)
    case Client.group_find(endpoint, name: group_name) do
      {:ok, group} ->
        do_delete(endpoint, group)
      _ ->
        display_error("Unable to find group named #{group_name}")
    end
  end

  defp do_delete(endpoint, group) do
    case Client.group_delete(endpoint, group.id) do
      :ok ->
        display_output("Deleted #{group.name}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

end

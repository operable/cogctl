defmodule Cogctl.Actions.Groups.Info do
  use Cogctl.Action, "groups info"

  alias Cogctl.Actions.Groups
  alias CogApi.HTTP.Client

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    do_info(endpoint, :proplists.get_value(:group, options))
  end

  defp do_info(_endpoint, :undefined), do: display_arguments_error
  defp do_info(endpoint, group_name) do
    case Client.group_find(endpoint, name: group_name) do
      {:ok, group} ->
        Groups.render(group)
      {:error, error} ->
        display_error(error["errors"])
    end
  end

end

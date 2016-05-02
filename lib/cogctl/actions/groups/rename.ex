defmodule Cogctl.Actions.Groups.Rename do
  use Cogctl.Action, "groups rename"

  alias Cogctl.Actions.Groups
  alias CogApi.HTTP.Client

  def option_spec do
    [{:group, :undefined, :undefined, :string, 'Group id (required)'},
     {:name, :undefined, :undefined, :string, 'Name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    group = Groups.find_by_name(endpoint, :proplists.get_value(:group, options))
    do_rename(endpoint, group, :proplists.get_value(:name, options))
  end

  defp do_rename(_endpoint, :undefined, _), do: display_arguments_error
  defp do_rename(_endpoint, _, :undefined), do: display_arguments_error

  defp do_rename(endpoint, group, name) do
    case Client.group_update(endpoint, group.id, %{name: name}) do
      {:ok, updated} ->
        Groups.render(updated, "Renamed group #{group.name} to #{updated.name}")
      {:error, message} ->
        display_error(message)
    end
  end
end

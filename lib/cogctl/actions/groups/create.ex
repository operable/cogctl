defmodule Cogctl.Actions.Groups.Create do
  use Cogctl.Action, "groups create"
  alias Cogctl.Table

  def option_spec do
    [{:name, :undefined, 'name', {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    with_authentication(endpoint,
                        &do_create(&1, :proplists.get_value(:name, options)))
  end

  defp do_create(_endpoint, :undefined) do
    display_arguments_error
  end

  defp do_create(endpoint, name) do
    case CogApi.HTTP.Old.group_create(endpoint, %{group: %{name: name}}) do
      {:ok, resp} ->
        group = resp["group"]
        name = group["name"]

        group_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}] do
          [title, group[attr]]
        end

        display_output("""
        Created #{name}

        #{Table.format(group_attrs, false)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

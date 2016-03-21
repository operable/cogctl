defmodule Cogctl.Actions.Groups.Update do
  use Cogctl.Action, "groups update"
  alias Cogctl.Table

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group id (required)'},
     {:name, :undefined, 'name', {:string, :undefined}, 'Name'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [name: :optional])
    with_authentication(endpoint,
                        &do_update(&1, :proplists.get_value(:group, options), params))
  end

  defp do_update(_endpoint, :undefined, _options) do
    display_arguments_error
  end

  defp do_update(_endpoint, _group_name, :error) do
    display_arguments_error
  end

  defp do_update(endpoint, group_name, {:ok, params}) do
    case CogApi.HTTP.Old.group_update(endpoint, group_name, %{group: params}) do
      {:ok, resp} ->
        group = resp["group"]
        group_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}] do
          [title, group[attr]]
        end

        display_output("""
        Updated #{group_name}

        #{Table.format(group_attrs, false)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

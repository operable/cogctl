defmodule Cogctl.Actions.Groups.Info do
  use Cogctl.Action, "groups info"
  alias Cogctl.Actions.Groups
  alias Cogctl.Table

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    with_authentication(endpoint,
                        &do_info(&1, :proplists.get_value(:group, options)))
  end

  defp do_info(_endpoint, :undefined) do
    display_arguments_error
  end

  defp do_info(endpoint, group_name) do
    case CogApi.HTTP.Internal.group_show(endpoint, group_name) do
      {:ok, resp} ->
        group = resp["group"]

        group_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}] do
          [title, group[attr]]
        end

        display_output("""
        #{Table.format(group_attrs, false)}

        #{Groups.render_memberships(group)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

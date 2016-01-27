defmodule Cogctl.Actions.Groups.Info do
  use Cogctl.Action, "groups info"
  alias Cogctl.Actions.Groups
  alias Cogctl.CogApi
  alias Cogctl.Table

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_info(client, :proplists.get_value(:group, options))
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_info(_client, :undefined) do
    display_arguments_error
  end

  defp do_info(client, group_name) do
    case CogApi.group_show(client, group_name) do
      {:ok, resp} ->
        group = resp["group"]

        group_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}] do
          [title, group[attr]]
        end

        display_output("""
        #{Table.format(group_attrs)}

        #{Groups.render_memberships(group)}
        """)
      {:error, error} ->
        display_error(error["error"])
    end
  end
end

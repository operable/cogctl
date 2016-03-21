defmodule Cogctl.Actions.Roles.Create do
  use Cogctl.Action, "roles create"
  alias Cogctl.Table

  def option_spec do
    [{:name, :undefined, 'name', {:string, :undefined}, 'Role name (required)'}]
  end

  def run(options, _args, _config, client) do
    with_authentication(client,
                        &do_create(&1, :proplists.get_value(:name, options)))
  end

  defp do_create(_client, :undefined) do
    display_arguments_error
  end

  defp do_create(client, name) do
    case CogApi.role_create(client, %{role: %{name: name}}) do
      {:ok, resp} ->
        role = resp["role"]
        name = role["name"]

        role_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}] do
          [title, role[attr]]
        end

        display_output("""
        Created #{name}

        #{Table.format(role_attrs, false)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["error"])
    end
  end
end

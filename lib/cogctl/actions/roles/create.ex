defmodule Cogctl.Actions.Roles.Create do
  use Cogctl.Action, "roles create"
  alias Cogctl.CogApi
  alias Cogctl.Table

  def option_spec do
    [{:name, :undefined, 'name', {:string, :undefined}, 'Role name (required)'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_create(client, :proplists.get_value(:name, options))
      {:error, error} ->
        display_error(error["error"])
    end
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

        #{Table.format(role_attrs)}
        """)
      {:error, error} ->
        display_error(error["error"])
    end
  end
end

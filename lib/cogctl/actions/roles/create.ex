defmodule Cogctl.Actions.Roles.Create do
  use Cogctl.Action, "roles create"
  alias Cogctl.Table

  def option_spec do
    [{:name, :undefined, 'name', {:string, :undefined}, 'Role name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    with_authentication(endpoint,
                        &do_create(&1, :proplists.get_value(:name, options)))
  end

  defp do_create(_endpoint, :undefined) do
    display_arguments_error
  end

  defp do_create(endpoint, name) do
    case CogApi.HTTP.Roles.create(endpoint, %{name: name}) do
      {:ok, role} ->
        name = role.name

        role_attrs = for {title, attr} <- [{"ID", :id}, {"Name", :name}] do
          [title, Map.fetch!(role, attr)]
        end

        display_output("""
        Created #{name}

        #{Table.format(role_attrs, false)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error)
    end
  end
end

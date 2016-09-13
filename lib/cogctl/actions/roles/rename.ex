defmodule Cogctl.Actions.Roles.Rename do
  use Cogctl.Action, "roles rename"
  alias Cogctl.Table

  def option_spec do
    [{:role, :undefined, :undefined, :string, 'Role id (required)'},
     {:name, :undefined, :undefined, {:string, :undefined}, 'Name'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [:role, :name])
    with_authentication(endpoint,
                        &do_rename(&1, :proplists.get_value(:role, options), params))
  end

  defp do_rename(endpoint, role_name, params) do
    case CogApi.HTTP.Internal.role_update(endpoint, role_name, %{role: params}) do
      {:ok, resp} ->
        role = resp["role"]
        role_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}] do
          [title, role[attr]]
        end

        display_output("""
        Renamed #{role_name} to #{params[:name]}

        #{Table.format(role_attrs, false)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

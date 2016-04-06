defmodule Cogctl.Actions.Roles.Grant do
  use Cogctl.Action, "roles grant"

  alias CogApi.HTTP
  alias Cogctl.Actions.Groups
  alias Cogctl.Actions.Roles

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role name (required)'},
     {:group, :undefined, 'group', {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    group = Groups.find_by_name(endpoint, :proplists.get_value(:group, options))
    role = Roles.find_by_name(endpoint, :proplists.get_value(:role, options))
    do_grant(endpoint, role, group)
  end

  defp do_grant(_endpoint, :undefined, _group), do: display_arguments_error
  defp do_grant(_endpoint, _role, :undefined), do: display_arguments_error

  defp do_grant(endpoint, role, group) do
    case HTTP.Roles.grant(endpoint, role, group) do
      {:ok, _} ->
        display_output("Granted #{role.name} to #{group.name}")
      {:error, error} ->
        display_error(error)
    end
  end
end

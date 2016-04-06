defmodule Cogctl.Actions.Roles.Grant do
  use Cogctl.Action, "roles grant"

  alias CogApi.HTTP.Client

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role name (required)'},
     {:group, :undefined, 'group', {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    group = Client.group_find(endpoint, name: :proplists.get_value(:group, options))
    role = Client.role_show(endpoint, %{name: :proplists.get_value(:role, options)})
    do_grant(endpoint, role, group)
  end

  defp do_grant(_endpoint, {:error, _}, _), do: display_arguments_error
  defp do_grant(_endpoint, _, {:error, _}), do: display_arguments_error

  defp do_grant(endpoint, {:ok, role}, {:ok, group}) do
    case Client.role_grant(endpoint, role, group) do
      {:ok, _} ->
        display_output("Granted #{role.name} to #{group.name}")
      {:error, error} ->
        display_error(error)
    end
  end
end

defmodule Cogctl.Actions.Groups.Add do
  use Cogctl.Action, "groups add"

  alias Cogctl.Actions.Groups
  alias CogApi.Resources.User
  alias CogApi.HTTP.Client

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'},
     {:email, :undefined, 'email', {:string, :undefined}, 'User email address (required)'}]
  end

  def run(options, args, config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, args, config, &1))
  end

  def run(options, _args, _config, endpoint) do
    group_name = :proplists.get_value(:group, options)
    case Client.group_find(endpoint, name: group_name) do
      {:ok, group} ->
        user = option_to_struct(options, :email, %User{}, :email_address)
        do_add(endpoint, group, user)
      _ ->
        display_error("Unable to find group named #{group_name}")
    end
  end

  defp do_add(_endpoint, :undefined, _), do: display_arguments_error
  defp do_add(_endpoint, _, :undefined), do: display_arguments_error

  defp do_add(endpoint, group, user) do
    case Client.group_add_user(endpoint, group, user) do
      {:ok, updated_group} ->
        message = "Added #{user.email_address} to #{group.name}"
        Groups.render(updated_group, message)
      {:error, message} ->
        display_error(message)
    end
  end

end

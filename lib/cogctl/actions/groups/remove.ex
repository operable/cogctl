defmodule Cogctl.Actions.Groups.Remove do
  use Cogctl.Action, "groups remove"

  alias Cogctl.Actions.Groups
  alias CogApi.Resources.User
  alias CogApi.HTTP.Client

  def option_spec do
    [{:group, :undefined, :undefined, :string, 'Group name (required)'},
     {:email, :undefined, 'email', :string, 'User email address (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    group = Groups.find_by_name(endpoint, :proplists.get_value(:group, options))
    user = option_to_struct(options, :email, %User{}, :email_address)
    do_remove(endpoint, group, user)
  end

  defp do_remove(_endpoint, :undefined, _), do: display_arguments_error
  defp do_remove(_endpoint, _, :undefined), do: display_arguments_error

  defp do_remove(endpoint, group, user) do
    case Client.group_remove_user(endpoint, group, user) do
      {:ok, updated_group} ->
        message = "Removed #{user.email_address} from #{group.name}"
        Groups.render(updated_group, message)
      {:error, message} ->
        display_error(message)
    end
  end

end

defmodule Cogctl.Actions.Users.Info do
  use Cogctl.Action, "users info"
  alias Cogctl.Table

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'User username (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    with_authentication(endpoint,
                        &do_info(&1, :proplists.get_value(:user, options)))
  end

  defp do_info(_endpoint, :undefined) do
    display_arguments_error
  end

  defp do_info(endpoint, user_username) do
    case CogApi.HTTP.Old.user_show(endpoint, user_username) do
      {:ok, resp} ->
        user = resp["user"]

        user_attr = for {title, attr} <- [{"ID", "id"}, {"Username", "username"}, {"First Name", "first_name"}, {"Last Name", "last_name"}, {"Email", "email_address"}] do
          [title, user[attr]]
        end

        groups = Enum.map(user["groups"], fn(membership) ->
                   [membership["name"], membership["id"]]
                 end)

        display_output("""
                       #{Table.format(user_attr, false)}

                       Groups
                       #{Table.format([["NAME", "ID"]] ++ groups, true)}
                       """ |> String.rstrip)
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

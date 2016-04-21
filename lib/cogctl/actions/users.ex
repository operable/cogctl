defmodule Cogctl.Actions.Users do
  use Cogctl.Action, "users"
  import Cogctl.Actions.Users.Util, only: [render: 2]

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp generate_table_row(user) do
    [user.username, get_name(user.first_name, user.last_name), user.email_address]
  end

  defp get_name(first, last) do
    Enum.reject([first, last], &is_nil/1)
    |> Enum.join(" ")
  end

  defp do_list(endpoint) do
    case CogApi.HTTP.Client.user_index(endpoint) do
      {:ok, users} ->
        user_attrs = for user <- users do
          generate_table_row(user)
        end

        render([["USERNAME", "FULL NAME", "EMAIL_ADDRESS"]] ++ user_attrs, true)
      {:error, error} ->
        display_error(error)
    end
  end
end

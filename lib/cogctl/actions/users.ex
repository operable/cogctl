defmodule Cogctl.Actions.Users do
  use Cogctl.Action, "users"
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp generate_table_row(username, nil, nil), do: [username, ""]
  defp generate_table_row(username, first, nil), do: [username, first]
  defp generate_table_row(username, nil, last), do: [username, last]
  defp generate_table_row(username, first, last), do: [username, first <> " " <> last]

  defp do_list(endpoint) do
    case CogApi.HTTP.Users.index(endpoint) do
      {:ok, users} ->
        user_attrs = for user <- users do
          generate_table_row(user.username, user.first_name, user.last_name)
        end

        display_output(Table.format([["USERNAME", "FULL NAME"]] ++ user_attrs, true))
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

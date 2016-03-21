defmodule Cogctl.Actions.Users do
  use Cogctl.Action, "users"
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, client),
    do: with_authentication(client, &do_list/1)

  defp do_list(client) do
    case CogApi.user_index(client) do
      {:ok, resp} ->
        users = resp["users"]
        user_attrs = for user <- users do
          [user["username"], user["first_name"] <> " " <> user["last_name"]]
        end

        display_output(Table.format([["USERNAME", "FULL NAME"]] ++ user_attrs, true))
      {:error, error} ->
        display_error(error["error"])
    end
  end
end

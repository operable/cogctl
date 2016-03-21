defmodule Cogctl.Actions.Roles do
  use Cogctl.Action, "roles"
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, client),
    do: with_authentication(client, &do_list/1)

  defp do_list(client) do
    case CogApi.role_index(client) do
      {:ok, resp} ->
        roles = resp["roles"]
        role_attrs = for role <- roles do
          [role["name"], role["id"]]
        end

        display_output(Table.format([["NAME", "ID"]] ++ role_attrs, true))
      {:error, error} ->
        display_error(error["error"])
    end
  end
end

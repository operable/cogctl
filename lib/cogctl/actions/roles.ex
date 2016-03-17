defmodule Cogctl.Actions.Roles do
  use Cogctl.Action, "roles"
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp do_list(endpoint) do
    case CogApi.HTTP.Roles.role_index(endpoint) do
      {:ok, roles} ->

        role_attrs = for role <- roles do
          [Map.fetch!(role, :name), Map.fetch!(role, :id)]
        end

        display_output(Table.format([["NAME", "ID"]] ++ role_attrs, true))
      {:error, error} ->
        display_error(error)
    end
  end
end

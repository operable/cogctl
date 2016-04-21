defmodule Cogctl.Actions.Roles do
  use Cogctl.Action, "roles"

  alias Cogctl.Table
  alias CogApi.HTTP.Client

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp do_list(endpoint) do
    case Client.role_index(endpoint) do
      {:ok, roles} ->
        role_attrs = for role <- roles do
          [Map.fetch!(role, :name), Map.fetch!(role, :id)]
        end

        display_output(Table.format([["NAME", "ID"]] ++ role_attrs, true))
      {:error, error} ->
        display_error(error)
    end
  end

  def find_by_name(endpoint, name) do
    case Client.role_show(endpoint, %{name: name}) do
      {:ok, role} ->
        role
      _ ->
        :undefined
    end
  end

end

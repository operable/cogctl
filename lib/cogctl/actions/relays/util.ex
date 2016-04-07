defmodule Cogctl.Actions.Relays.Util do
  alias Cogctl.Table
  import Cogctl.ActionUtil , only: [display_output: 1, display_error: 1]

  def get_details(relay) do
    [{"Name", Map.fetch!(relay, :name)},
     {"ID", Map.fetch!(relay, :id)},
     {"Status", get_status(Map.fetch!(relay, :enabled))},
     {"Creation Time", Map.fetch!(relay, :inserted_at)},
     {"Description", to_string(Map.fetch!(relay, :description))}]
  end

  def get_status(true), do: "enabled"
  def get_status(false), do: "disabled"

  def render(relay_info, sort) do
    Table.format(relay_info, sort) |> display_output
  end

  def render(relay_info, sort, message) do
    message <> "\n\n" <> Table.format(relay_info, sort) |> display_output
  end

  def render(relay_info, group_info, sort, nil) do
    Table.format(relay_info, false) <> "\n\nRelay Groups\n" <> Table.format(group_info, sort)
    |> display_output
  end
  def render(relay_info, group_info, sort, message) do
    message <> "\n\n" <> Table.format(relay_info, false) <> "\n\nRelay Groups\n" <> Table.format(group_info, sort)
    |> display_output
  end

  def update_status(endpoint, relay_name, status) do
    case CogApi.HTTP.Client.relay_update(%{name: relay_name}, %{enabled: status}, endpoint) do
      {:ok, _} ->
        status_info = get_status(status)
        |> String.capitalize 
        status_info <> " " <> relay_name
        |> display_output
      {:error, error} ->
        display_error(error)
    end
  end
    
end

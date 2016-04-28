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
  def get_status(value), do: value

  # If the errorcount is not equal to 0, be sure that an error code
  # is returned upon execution
  def render(relay, {relay_group_msgs, 0}) do
    render_output(relay_group_msgs, relay)
  end
  def render(relay, {relay_group_msgs, _errorcount}) do
    render_output(relay_group_msgs, relay)
    :error
  end
  def render(relay_info, sort) do
    Table.format(relay_info, sort) |> display_output
  end

  # If the errorcount is not equal to 0, be sure that an error code
  # is returned upon execution
  def render({relay_group_messages, 0}, relay_info, sort) do
    render_output(relay_group_messages, relay_info, sort)
  end
  def render({relay_group_messages, _errorcount}, relay_info, sort) do
    render_output(relay_group_messages, relay_info, sort)
    :error
  end
  def render(relay_info, sort, message) do
    message <> "\n\n" <> Table.format(relay_info, sort) |> display_output
  end

  # If the errorcount is not equal to 0, be sure that an error code
  # is returned upon execution
  def render({relay_group_messages, 0}, relay_info, sort, message) do
    render_output(relay_group_messages, relay_info, sort, message)
  end
  def render({relay_group_messages, _errorcount}, relay_info, sort, message) do
    render_output(relay_group_messages, relay_info, sort, message)
    :error
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

  defp render_output(relay_group_msgs, relay) do
    relay_info = format_table(relay)

    Table.format(relay_info, false) <> "\n\n" <> Table.format(relay_group_msgs, false)
    |> display_output
  end

  defp render_output(relay_group_messages, relay_info, sort) do
    group_message = Enum.join(relay_group_messages, "\n")
    Table.format(relay_info, sort) <> "\n\n" <> group_message
    |> display_output
  end

  defp render_output(relay_group_messages, relay_info, sort, message) do
    group_message = Enum.join(relay_group_messages, "\n")
    message <> group_message <> "\n\n" <> Table.format(relay_info, sort)
    |> display_output
  end

  defp format_table(relay) do
    [
      {"ID",     relay.id},
      {"Name",   relay.name},
      {"Status", get_status(relay.enabled)},
    ]
  end

end

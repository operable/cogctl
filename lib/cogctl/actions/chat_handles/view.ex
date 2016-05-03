defmodule Cogctl.Actions.ChatHandles.View do
  alias Cogctl.Table
  import Cogctl.ActionUtil , only: [display_output: 1]

  def render(chat_handles) when is_list(chat_handles) do
    format_table(chat_handles)
    |> Table.format(true)
    |> display_output
  end
  def render(handle) do
    handle_info = format_table(handle)

    Table.format(handle_info, false)
    |> display_output
  end

  def render_resource(nil), do: []
  def render_resource(handles) do
    chat_handles = Enum.map(handles, fn(handle) ->
      get_in(handle, ["chat_provider", "name"]) <> ":" <> Map.get(handle, "handle")
    end)
    |> Enum.sort
    |> Enum.join(", ")

    [["Chat-handles", chat_handles]]
  end

  defp format_table(chat_handles) when is_list(chat_handles) do
    rows = Enum.map(chat_handles, fn(chat_handle) ->
      [get_in(chat_handle, ["user", "username"]),
       get_in(chat_handle, ["chat_provider", "name"]),
       Map.get(chat_handle, "handle")]
    end)
    [["USER", "CHAT PROVIDER", "HANDLE"]] ++ rows
  end
  defp format_table(handle) do
    [
      ["ID",            Map.get(handle, "id")],
      ["User",          get_in(handle, ["user", "username"])],
      ["Chat Provider", get_in(handle, ["chat_provider", "name"])],
      ["Handle",        Map.get(handle, "handle")]
    ]
  end

end

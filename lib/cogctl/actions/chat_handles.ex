defmodule Cogctl.Actions.ChatHandles do
  use Cogctl.Action, "chat-handles"
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp do_list(endpoint) do
    case CogApi.HTTP.Internal.chat_handle_index(endpoint) do
      {:ok, resp} ->
        chat_handles = resp["chat_handles"]
        chat_handle_attrs = for chat_handle <- chat_handles do
          [chat_handle["user"]["username"], chat_handle["chat_provider"]["name"], chat_handle["handle"]]
        end

        display_output(Table.format([["USER", "CHAT PROVIDER", "HANDLE"]] ++ chat_handle_attrs, true))
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

defmodule Cogctl.Actions.ChatHandles do
  use Cogctl.Action, "chat-handles"
  alias Cogctl.CogApi
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_list(client)
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_list(client) do
    case CogApi.chat_handle_index(client) do
      {:ok, resp} ->
        chat_handles = resp["chat_handles"]
        chat_handle_attrs = for chat_handle <- chat_handles do
          [chat_handle["user"]["username"], chat_handle["chat_provider"]["name"], chat_handle["handle"]]
        end

        display_output(Table.format([["USER", "CHAT PROVIDER", "HANDLE"]] ++ chat_handle_attrs))
      {:error, error} ->
        display_error(error["error"])
    end
  end
end

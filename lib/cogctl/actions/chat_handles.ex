defmodule Cogctl.Actions.ChatHandles do
  use Cogctl.Action, "chat-handles"
  alias Cogctl.Actions.ChatHandles.View, as: ChatHandleView

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp do_list(endpoint) do
    case CogApi.HTTP.Internal.chat_handle_index(endpoint) do
      {:ok, resp} ->
        chat_handles = resp["chat_handles"]
        ChatHandleView.render(chat_handles)

      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

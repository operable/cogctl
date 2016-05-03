defmodule Cogctl.Actions.ChatHandles.Create do
  use Cogctl.Action, "chat-handles create"
  alias Cogctl.Actions.ChatHandles.View, as: ChatHandleView

  def option_spec do
    [{:user, :undefined, 'user', :string, 'Username of user to add handle to (required)'},
     {:chat_provider, :undefined, 'chat-provider', :string, 'Chat provider name (required)'},
     {:handle, :undefined, 'handle', {:string, :undefined}, 'Handle (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options)
    with_authentication(endpoint, &do_create(&1, params))
  end

  defp do_create(endpoint, params) do
    case CogApi.HTTP.Internal.chat_handle_create(endpoint, %{chat_handle: params}) do
      {:ok, resp} ->
        chat_handle = resp["chat_handle"]
        ChatHandleView.render(chat_handle)
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

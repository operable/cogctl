defmodule Cogctl.Actions.ChatHandles.Create do
  use Cogctl.Action, "chat-handles create"
  alias Cogctl.Actions.ChatHandles.View, as: ChatHandleView

  def option_spec do
    [{:user, :undefined, 'user', {:string, :undefined}, 'Username of user to add handle to (required)'},
     {:chat_provider, :undefined, 'chat-provider', {:string, :undefined}, 'Chat provider name (required)'},
     {:handle, :undefined, 'handle', {:string, :undefined}, 'Handle (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    case convert_to_params(options, [user: :required,
                                     chat_provider: :required,
                                     handle: :required]) do
      {:ok, params} ->
        with_authentication(endpoint, &do_create(&1, params))
      {:error, {:missing_params, missing_params}} ->
        display_arguments_error(missing_params)
    end
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

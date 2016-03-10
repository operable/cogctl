defmodule Cogctl.Actions.ChatHandles.Delete do
  use Cogctl.Action, "chat-handles delete"

  def option_spec do
    [{:user, :undefined, 'user', {:string, :undefined}, 'Username user that owns the handle to delete (required)'},
     {:chat_provider, :undefined, 'chat-provider', {:string, :undefined}, 'Chat provider name (required)'}]
  end

  def run(options, _args, _config, client) do
    case CogApi.authenticate(client) do
      {:ok, client} ->
        params = convert_to_params(options, [user: :required, chat_provider: :required])
        do_delete(client, params)
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_delete(_client, :error) do
    display_arguments_error
  end

  defp do_delete(client, {:ok, params}) do
    case CogApi.chat_handle_delete(client, %{chat_handle: params}) do
      :ok ->
        display_output("Deleted chat handle owned by #{params[:user]} for #{params[:chat_provider]} chat provider")
      {:error, error} ->
        display_error(error["error"])
    end
  end
end

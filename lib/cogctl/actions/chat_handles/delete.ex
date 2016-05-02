defmodule Cogctl.Actions.ChatHandles.Delete do
  use Cogctl.Action, "chat-handles delete"

  def option_spec do
    [{:user, :undefined, 'user', :string, 'Username user that owns the handle to delete (required)'},
     {:chat_provider, :undefined, 'chat-provider', :string, 'Chat provider name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options)
    with_authentication(endpoint, &do_delete(&1, params))
  end

  defp do_delete(endpoint, params) do
    case CogApi.HTTP.Internal.chat_handle_delete(endpoint, %{chat_handle: params}) do
      :ok ->
        display_output("Deleted chat handle owned by #{params[:user]} for #{params[:chat_provider]} chat provider")
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

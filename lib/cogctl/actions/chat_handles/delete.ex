defmodule Cogctl.Actions.ChatHandles.Delete do
  use Cogctl.Action, "chat-handles delete"
  alias Cogctl.CogApi

  # Whitelisted options passed as params to api client
  @params [:user, :chat_provider]

  def option_spec do
    [{:user, :undefined, 'user', {:string, :undefined}, 'Username user that owns the handle to delete (required)'},
     {:chat_provider, :undefined, 'chat-provider', {:string, :undefined}, 'Chat provider name (required)'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, make_chat_handle_params(options))
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

  defp make_chat_handle_params(options) do
    options = Keyword.take(options, @params)

    case Enum.any?(options, &match?({_, :undefined}, &1)) do
      false ->
        {:ok, Enum.into(options, %{})}
      true ->
        :error
    end
  end
end

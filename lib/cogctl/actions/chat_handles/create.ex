defmodule Cogctl.Actions.ChatHandles.Create do
  use Cogctl.Action, "chat-handles create"
  alias Cogctl.CogApi
  alias Cogctl.Table

  # Whitelisted options passed as params to api client
  @params [:user, :chat_provider, :handle]

  def option_spec do
    [{:user, :undefined, 'user', {:string, :undefined}, 'Username of user to add handle to (required)'},
     {:chat_provider, :undefined, 'chat-provider', {:string, :undefined}, 'Chat provider name (required)'},
     {:handle, :undefined, 'handle', {:string, :undefined}, 'Handle (required)'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_create(client, options)
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_create(_client, :error) do
    display_arguments_error
  end

  defp do_create(client, {:ok, params}) do
    case CogApi.chat_handle_create(client, %{chat_handle: params}) do
      {:ok, resp} ->
        chat_handle = resp["chat_handle"]
        user = chat_handle["user"]["username"]
        chat_provider = chat_handle["chat_provider"]["name"]

        chat_handle = Map.merge(chat_handle, %{"user" => user, "chat_provider" => chat_provider})

        chat_handle_attrs = for {title, attr} <- [{"ID", "id"}, {"User", "user"}, {"Chat Provider", "chat_provider"}, {"Handle", "handle"}] do
          [title, chat_handle[attr]]
        end

        display_output("""
        Created #{chat_handle["handle"]} for #{chat_provider} chat provider

        #{Table.format(chat_handle_attrs)}
        """)
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

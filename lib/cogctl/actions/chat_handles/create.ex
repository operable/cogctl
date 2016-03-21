defmodule Cogctl.Actions.ChatHandles.Create do
  use Cogctl.Action, "chat-handles create"
  alias Cogctl.Table

  def option_spec do
    [{:user, :undefined, 'user', {:string, :undefined}, 'Username of user to add handle to (required)'},
     {:chat_provider, :undefined, 'chat-provider', {:string, :undefined}, 'Chat provider name (required)'},
     {:handle, :undefined, 'handle', {:string, :undefined}, 'Handle (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [user: :required, chat_provider: :required, handle: :required])
    with_authentication(endpoint, &do_create(&1, params))
  end

  defp do_create(_endpoint, :error) do
    display_arguments_error
  end

  defp do_create(endpoint, {:ok, params}) do
    case CogApi.HTTP.Old.chat_handle_create(endpoint, %{chat_handle: params}) do
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

        #{Table.format(chat_handle_attrs, false)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end

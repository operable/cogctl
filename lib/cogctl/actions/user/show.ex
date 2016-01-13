defmodule Cogctl.Actions.User.Show do
  use Cogctl.Action, "user show"
  alias Cogctl.CogApi

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'User id'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_show(client, :proplists.get_value(:user, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  def do_show(client, user_id) do
    case CogApi.user_show(client, user_id) do
      {:ok, resp} ->
        user = resp["user"]
        id = user["id"]
        first_name = user["first_name"]
        last_name = user["last_name"]
        username = user["username"]
        email_address = user["email_address"]
        IO.puts """
        User: #{first_name} #{last_name} (#{id})
          first_name: #{first_name}
          last_name: #{last_name}
          username: #{username}
          email_address: #{email_address}
        """ |> String.rstrip
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

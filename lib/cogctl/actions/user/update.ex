defmodule Cogctl.Actions.User.Update do
  use Cogctl.Action, "user update"
  alias Cogctl.CogApi

  @params [:first_name, :last_name, :email_address, :username, :password]

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'User id'},
     {:first_name, :undefined, 'first-name', {:string, :undefined}, 'First name'},
     {:last_name, :undefined, 'last-name', {:string, :undefined}, 'Last name'},
     {:email_address, :undefined, 'email', {:string, :undefined}, 'Email address'},
     {:username, :undefined, 'username', {:string, :undefined}, 'Username'},
     {:password, :undefined, 'password', {:string, :undefined}, 'Password'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_update(client, :proplists.get_value(:user, options), options)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  def do_update(client, user_id, options) do
    params = make_user_params(options)
    case CogApi.user_update(client, user_id, %{user: params}) do
      {:ok, resp} ->
        user = resp["user"]
        id = user["id"]
        first_name = user["first_name"]
        last_name = user["last_name"]
        email_address = user["email_address"]
        username = user["username"]

        IO.puts """
        Updated user: #{first_name} #{last_name} (#{id})
          first_name: #{first_name}
          last_name: #{last_name}
          email_address: #{email_address}
          username: #{username}
        """ |> String.rstrip
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  def make_user_params(options) do
    options
    |> Keyword.take(@params)
    |> Enum.reject(&match?({_, :undefined}, &1))
    |> Enum.into(%{})
  end
end

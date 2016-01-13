defmodule Cogctl.Actions.User.Create do
  use Cogctl.Action, "user create"
  alias Cogctl.CogApi

  @params [:first_name, :last_name, :email_address, :username, :password]

  def option_spec do
    [{:first_name, :undefined, 'first-name', {:string, :undefined}, 'First name'},
     {:last_name, :undefined, 'last-name', {:string, :undefined}, 'Last name'},
     {:email_address, :undefined, 'email', {:string, :undefined}, 'Email address'},
     {:username, :undefined, 'username', {:string, :undefined}, 'Username'},
     {:password, :undefined, 'password', {:string, :undefined}, 'Password'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_create(client, options)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  def do_create(client, options) do
    params = make_user_params(options)
    case CogApi.user_create(client, %{user: params}) do
      {:ok, resp} ->
        user = resp["user"]
        id = user["id"]
        first_name = user["first_name"]
        last_name = user["last_name"]
        IO.puts "Created user: #{first_name} #{last_name} (#{id})"
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

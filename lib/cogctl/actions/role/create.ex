defmodule Cogctl.Actions.Role.Create do
  use Cogctl.Action, "role create"
  alias Cogctl.CogApi

  @params [:name]

  def option_spec do
    [{:name, :undefined, 'name', {:string, :undefined}, 'Role name'}]
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
    params = make_role_params(options)
    case CogApi.role_create(client, %{role: params}) do
      {:ok, resp} ->
        role = resp["role"]
        id = role["id"]
        name = role["name"]
        IO.puts "Created role: #{name} (#{id})"
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  def make_role_params(options) do
    options
    |> Keyword.take(@params)
    |> Enum.reject(&match?({_, :undefined}, &1))
    |> Enum.into(%{})
  end
end

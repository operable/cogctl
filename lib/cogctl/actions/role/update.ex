defmodule Cogctl.Actions.Role.Update do
  use Cogctl.Action, "role update"
  alias Cogctl.CogApi

  @params [:name]

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role id'},
     {:name, :undefined, 'name', {:string, :undefined}, 'Name'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_update(client, :proplists.get_value(:role, options), options)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  def do_update(client, role_id, options) do
    params = make_role_params(options)
    case CogApi.role_update(client, role_id, %{role: params}) do
      {:ok, resp} ->
        role = resp["role"]
        id = role["id"]
        name = role["name"]
        IO.puts "Updated role: #{name} (#{id})"
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

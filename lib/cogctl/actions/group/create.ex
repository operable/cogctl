defmodule Cogctl.Actions.Group.Create do
  use Cogctl.Action, "group create"
  alias Cogctl.CogApi

  @params [:name]

  def option_spec do
    [{:name, :undefined, 'name', {:string, :undefined}, 'Group name'}]
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
    params = make_group_params(options)
    case CogApi.group_create(client, %{group: params}) do
      {:ok, resp} ->
        group = resp["group"]
        id = group["id"]
        name = group["name"]
        IO.puts "Created group: #{name} (#{id})"
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  def make_group_params(options) do
    options
    |> Keyword.take(@params)
    |> Enum.reject(&match?({_, :undefined}, &1))
    |> Enum.into(%{})
  end
end

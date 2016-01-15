defmodule Cogctl.Actions.Group.Update do
  use Cogctl.Action, "group update"
  alias Cogctl.CogApi

  @params [:name]

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group id'},
     {:name, :undefined, 'name', {:string, :undefined}, 'Name'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_update(client, :proplists.get_value(:group, options), options)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  def do_update(client, group_id, options) do
    params = make_group_params(options)
    case CogApi.group_update(client, group_id, %{group: params}) do
      {:ok, resp} ->
        group = resp["group"]
        id = group["id"]
        name = group["name"]
        IO.puts "Updated group: #{name} (#{id})"
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

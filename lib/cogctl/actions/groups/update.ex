defmodule Cogctl.Actions.Groups.Update do
  use Cogctl.Action, "groups update"
  alias Cogctl.CogApi
  alias Cogctl.Table

  # Whitelisted options passed as params to api client
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

  defp do_update(client, group_name, options) do
    params = make_group_params(options)
    case CogApi.group_update(client, group_name, %{group: params}) do
      {:ok, resp} ->
        group = resp["group"]
        group_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}] do
          [title, group[attr]]
        end

        IO.puts("Updated #{group_name}")
        IO.puts("")
        IO.puts(Table.format(group_attrs))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp make_group_params(options) do
    options
    |> Keyword.take(@params)
    |> Enum.reject(&match?({_, :undefined}, &1))
    |> Enum.into(%{})
  end
end

defmodule Cogctl.Actions.Groups.Create do
  use Cogctl.Action, "groups create"
  alias Cogctl.CogApi
  alias Cogctl.Table

  # Whitelisted options passed as params to api client
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

  defp do_create(client, options) do
    params = make_group_params(options)
    case CogApi.group_create(client, %{group: params}) do
      {:ok, resp} ->
        group = resp["group"]
        name = group["name"]

        group_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}] do
          [title, group[attr]]
        end

        IO.puts("Created #{name}")
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

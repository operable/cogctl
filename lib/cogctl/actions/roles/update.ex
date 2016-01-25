defmodule Cogctl.Actions.Roles.Update do
  use Cogctl.Action, "roles update"
  alias Cogctl.CogApi
  alias Cogctl.Table

  # Whitelisted options passed as params to api client
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

  defp do_update(client, role_name, options) do
    params = make_role_params(options)
    case CogApi.role_update(client, role_name, %{role: params}) do
      {:ok, resp} ->
        role = resp["role"]
        role_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}] do
          [title, role[attr]]
        end

        IO.puts("Updated #{role_name}")
        IO.puts("")
        IO.puts(Table.format(role_attrs))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp make_role_params(options) do
    options
    |> Keyword.take(@params)
    |> Enum.reject(&match?({_, :undefined}, &1))
    |> Enum.into(%{})
  end
end

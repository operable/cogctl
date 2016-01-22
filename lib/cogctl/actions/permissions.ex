defmodule Cogctl.Actions.Permissions do
  use Cogctl.Action, "permissions"
  alias Cogctl.CogApi
  alias Cogctl.Table

  @params [:user, :group]

  def option_spec do
    [{:user, :undefined, 'user', {:string, :undefined}, 'Username of user to filter permissions by'},
     {:group, :undefined, 'group', {:string, :undefined}, 'Name of group to filter permissions by'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_list(client, options)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_list(client, options) do
    params = make_permission_filter_params(options)
    case CogApi.permission_index(client, params) do
      {:ok, resp} ->
        permissions = resp["permissions"]
        permission_attrs = for permission <- permissions do
          namespace_name = permission["namespace"]["name"]
          permission_name = permission["name"]

          ["#{namespace_name}:#{permission_name}", permission["id"]]
        end

        IO.puts(Table.format([["NAME", "ID"]] ++ permission_attrs))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp make_permission_filter_params(options) do
    options
    |> Keyword.take(@params)
    |> Enum.reject(&match?({_, :undefined}, &1))
  end
end

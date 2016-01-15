defmodule Cogctl.Actions.Bundles.Info do
  use Cogctl.Action, "bundles info"
  alias Cogctl.CogApi
  alias Cogctl.Table

  def option_spec do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_info(client, :proplists.get_value(:bundle, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_info(client, bundle_name) do
    case CogApi.bundle_show(client, bundle_name) do
      {:ok, resp} ->
        bundle = resp["bundle"]

        bundle_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}, {"Installed", "inserted_at"}] do
          [title, bundle[attr]]
        end

        IO.puts(Table.format(bundle_attrs))
        IO.puts("")

        commands = for command <- bundle["commands"] do
          [command["name"], command["id"]]
        end

        IO.puts("Commands")
        IO.puts(Table.format([["NAME", "ID"]|commands]))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

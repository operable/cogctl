defmodule Cogctl.Actions.Bundles.Info do
  use Cogctl.Action, "bundles info"
  alias Cogctl.Actions.Bundles
  alias Cogctl.CogApi
  alias Cogctl.Table

  def option_spec do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name (required)'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_info(client, :proplists.get_value(:bundle, options))
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_info(_client, :undefined) do
    display_error("Missing required arguments")
  end

  defp do_info(client, bundle_name) do
    case CogApi.bundle_show(client, bundle_name) do
      {:ok, resp} ->
        bundle = resp["bundle"]

        status = Bundles.enabled_to_status(bundle["enabled"])
        bundle = Map.merge(bundle, %{"status" => status})

        bundle_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}, {"Status", "status"}, {"Installed", "inserted_at"}] do
          [title, bundle[attr]]
        end

        commands = for command <- bundle["commands"] do
          [command["name"], command["id"]]
        end

        display_output("""
        #{Table.format(bundle_attrs, false)}

        Commands
        #{Table.format([["NAME", "ID"]|commands], true)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["error"])
    end
  end
end

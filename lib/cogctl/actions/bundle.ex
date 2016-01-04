defmodule Cogctl.Actions.BundleList do

  use Cogctl.Action, "bundle list"
  alias Cogctl.CogApi

  def option_spec() do
    [{:bundle, ?b, 'bundle', {:string, :undefined}, 'Bundle id'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_list(:proplists.get_value(:bundle, options), client)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_list(:undefined, client) do
    case CogApi.list_all_bundles(client) do
      {:ok, resp} ->
        bundles = resp["bundles"]
        for bundle <- bundles do
          id = bundle["id"]
          name = bundle["name"]
          installed = bundle["inserted_at"]
          ns_id = get_in(bundle, ["namespace", "id"])
          IO.puts "Bundle: #{name} (#{id}, ns: #{ns_id})\nInstalled: #{installed}\n"
        end
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
  defp do_list(bundle_id, client) do
    case CogApi.bundle_info(client, bundle_id) do
      {:ok, resp} ->
        IO.puts "#{Map.keys(resp["bundle"])}"
        commands = get_in(resp, ["bundle", "commands"])
        id = get_in(resp, ["bundle", "id"])
        name = get_in(resp, ["bundle", "name"])
        installed = get_in(resp, ["bundle", "inserted_at"])
        ns_id = get_in(resp, ["bundle", "namespace", "id"])
        cmdout = Enum.join(for command <- commands do
                             "  #{command["name"]} (#{command["id"]})"
                            end, "\n")
        out = "Bundle: #{name} (#{id}, ns: #{ns_id})\nInstalled: #{installed}\n" <>
              "Commands (#{length(commands)})\n" <> cmdout
        IO.puts out
        :ok
    end
  end
end

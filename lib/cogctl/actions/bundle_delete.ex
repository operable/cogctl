defmodule Cogctl.Actions.BundleDelete do

  use Cogctl.Action, "bundle delete"
  alias Cogctl.CogApi

  def option_spec() do
    [{:bundle, ?b, 'bundle', {:string, :undefined}, 'Bundle id'}]
  end

  def run(options, _args,  _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(:proplists.get_value(:bundle, options), client)
      {:error, error} ->
        IO.puts "#{error["error"]}"
        :error
    end
  end

  defp do_delete(:undefined, _client) do
    IO.puts "[-b|--bundle] option is required"
    :error
  end
  defp do_delete(bundle_id, client) do
    case CogApi.bundle_delete(client, bundle_id) do
      :ok ->
        IO.puts "ok"
        :ok
      {:error, error} ->
        IO.puts "#{error["error"]}"
        :error
    end
  end

end

defmodule Cogctl.Actions.Bundles.Enable do
  use Cogctl.Action, "bundles enable"
  alias Cogctl.CogApi

  def option_spec() do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name'}]
  end

  def run(options, _args,  _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_enable(client, :proplists.get_value(:bundle, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
        :error
    end
  end

  defp do_enable(client, bundle_name) do
    case CogApi.bundle_enable(client, bundle_name) do
      {:ok, _} ->
        IO.puts "Enabled #{bundle_name}"
        :ok
      {:error, error} ->
        IO.puts "#{error["error"]}"
        :error
    end
  end
end

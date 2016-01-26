defmodule Cogctl.Actions.Bundles.Disable do
  use Cogctl.Action, "bundles disable"
  alias Cogctl.CogApi

  def option_spec() do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name'}]
  end

  def run(options, _args,  _config, profile) do
    IO.puts "#{inspect options}"
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_disable(client, :proplists.get_value(:bundle, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
        :error
    end
  end

  defp do_disable(client, bundle_name) do
    case CogApi.bundle_disable(client, bundle_name) do
      {:ok, _} ->
        IO.puts "Disabled #{bundle_name}"
        :ok
      {:error, error} ->
        IO.puts "#{error["error"]}"
        :error
    end
  end
end

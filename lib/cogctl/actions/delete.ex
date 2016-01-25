defmodule Cogctl.Actions.Bundles.Delete do
  use Cogctl.Action, "bundles delete"
  alias Cogctl.CogApi

  def option_spec do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name'}]
  end

  def run(options, _args,  _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, :proplists.get_value(:bundle, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
        :error
    end
  end

  defp do_delete(bundle_name, client) do
    case CogApi.bundle_delete(client, bundle_name) do
      :ok ->
        IO.puts "Deleted #{bundle_name}"
        :ok
      {:error, error} ->
        IO.puts "#{error["error"]}"
        :error
    end
  end

end

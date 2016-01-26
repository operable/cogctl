defmodule Cogctl.Actions.Bundles.Delete do
  use Cogctl.Action, "bundles delete"
  alias Cogctl.CogApi

  def option_spec do
    []
  end

  def run(_options, args,  _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, args)
      {:error, error} ->
        IO.puts "#{error["error"]}"
        :error
    end
  end

  defp do_delete(client, bundle_names) when is_list(bundle_names) do
    for bundle_name <- bundle_names do
      do_delete(client, bundle_name)
    end
  end

  defp do_delete(client, bundle_name) do
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

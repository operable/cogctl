defmodule Cogctl.Actions.Bundles do
  use Cogctl.Action, "bundles"
  alias Cogctl.CogApi
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_list(client)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_list(client) do
    case CogApi.bundle_index(client) do
      {:ok, resp} ->
        bundles = for bundle <- resp["bundles"] do
          [bundle["name"], bundle["inserted_at"]]
        end

        IO.puts(Table.format([["NAME", "INSTALLED"]] ++ bundles))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end

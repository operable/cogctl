defmodule Cogctl.Actions.Bundle.DynamicConfig.Create do
  use Cogctl.Action, "dynamic-config create"

  alias CogApi.HTTP.Client, as: CogClient
  alias Cogctl.Actions.Bundle.DynamicConfig.Util

  def option_spec do
    [{:bundle, 98, 'bundle', :string, 'Bundle name or id (required)'},
     {:file, :undefined, :undefined, :string, 'Path to config.yaml (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    bundle = Keyword.get(options, :bundle)
    config_file = Keyword.get(options, :file)
    with_authentication(endpoint, &do_create(&1, bundle, config_file))
  end

  defp do_create(endpoint, bundle, file_name) do
    with {:ok, bundle_id} <- Util.lookup_bundle(endpoint, bundle),
         {:ok, config} <- load_config_file(file_name),
         do: create_config(endpoint, bundle_id, config) |> render
  end

  defp render({:ok, %{"dynamic_configuration" => %{"bundle_name" => name}}}) do
    "Dynamic config for bundle '#{name}' saved successfully." |> display_output
  end
  defp render(error) do
    IO.puts "Error: #{inspect error}"
  end

  defp load_config_file(file_name) do
    try do
      {:ok, YamlElixir.read_from_file(file_name)}
    catch
      _ ->
        {:error, "Unable to read file '#{file_name}'"}
    end
  end

  defp create_config(endpoint, bundle_id, config) do
    CogClient.bundle_create_dynamic_config(endpoint, bundle_id, config)
  end

end

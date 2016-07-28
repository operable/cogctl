defmodule Cogctl.Actions.Bundle.DynamicConfig.Create do
  use Cogctl.Action, "dynamic-config create"

  alias CogApi.HTTP.Client, as: CogClient
  alias Cogctl.Actions.Bundle.DynamicConfig.Util

  def option_spec do
    [{:bundle, :undefined, :undefined, :string, 'Bundle name or id (required)'},
     {:layer, ?l, 'layer', {:string, :undefined}, 'Configuration layer; if not specified, "base" is assumed'},
     {:file, :undefined, :undefined, :string, 'Path to config.yaml (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    bundle = Keyword.get(options, :bundle)
    config_file = Keyword.get(options, :file)

    with {:ok, {layer, name}} <- Util.layer_and_name(options),
      do: with_authentication(endpoint, &do_create(&1, bundle, layer, name, config_file))
  end

  defp do_create(endpoint, bundle, layer, name, file_name) do
    with {:ok, bundle_id} <- Util.lookup_bundle(endpoint, bundle),
    {:ok, config} <- load_config_file(file_name),
      do: create_config(endpoint, bundle_id, layer, name, config) |> render
  end

  defp render({:ok, %{"dynamic_configuration" => %{"bundle_name" => bundle_name, "layer" => layer, "name" => name}}}) do
    message = if layer == "base" do
      "Base dynamic config layer for bundle '#{bundle_name}' saved successfully"
    else
      "#{layer}/#{name} dynamic config layer for bundle '#{bundle_name}' saved successfully"
    end

    display_output(message, true)
  end
  defp render({:error, reason}) do
    "#{reason}" |> display_error
  end

  defp load_config_file(file_name) do
    try do
      {:ok, YamlElixir.read_from_file(file_name)}
    catch
      _ ->
        {:error, "Unable to read file '#{file_name}'"}
    end
  end

  defp create_config(endpoint, bundle_id, layer, name, config) do
    CogClient.bundle_create_dynamic_config(endpoint, bundle_id, layer, name, config)
  end

end

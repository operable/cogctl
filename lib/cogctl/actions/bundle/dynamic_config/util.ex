defmodule Cogctl.Actions.Bundle.DynamicConfig.Util do

  alias CogApi.HTTP.Client, as: CogClient

  @doc """
  Given a bundle id or name return the corresponding id. If an
  id is given, validate it as a UUID.
  """
  def lookup_bundle(endpoint, bundle) do
    try do
      uuid = UUID.string_to_binary!(bundle)
      case CogClient.bundle_show(endpoint, uuid) do
        {:ok, bundle} ->
          {:ok, bundle.id}
        error ->
          format_error(error, bundle)
      end
    rescue
      _ ->
        case CogClient.bundle_show_by_name(endpoint, bundle) do
          {:ok, bundle} ->
            {:ok, bundle.id}
          error ->
            format_error(error, bundle)
        end
    end
  end

  # Extract valid layer and name option values.
  def layer_and_name(options) do
    case Keyword.get(options, :layer) do
      default when default in [:undefined, "base"] ->
        {:ok, {"base", nil}}
      layer_and_name ->
        case String.split(layer_and_name, "/", parts: 2) do
          [layer, name] ->
            {:ok, {layer, name}}
          _ ->
            {:error, "Must specify a layer as 'base', 'room/$NAME', or 'user/$NAME'"}
        end
    end
  end

  defp format_error({:error, [nil]}, bundle) do
    {:error, "Bundle '#{bundle}' not found."}
  end
  defp format_error(error, _bundle) do
    error
  end

end

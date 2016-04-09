defmodule Cogctl.Actions.Bundles.Create do
  use Cogctl.Action, "bundles create"

  alias Cogctl.Actions.Bundles
  alias CogApi.HTTP.Client

  def option_spec do
    [{:file, :undefined, :undefined, {:string, :undefined}, 'Path to your bundle config file (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    do_create(endpoint, :proplists.get_value(:file, options))
  end

  defp do_create(_endpoint, :undefined),
    do: display_arguments_error
  defp do_create(endpoint, bundle_file) do
    results = with {:ok, config} <- Spanner.Config.Parser.read_from_file(bundle_file),
                   :ok           <- Spanner.Config.validate(config),
                 do: Client.bundle_create(endpoint, config)

    case results do
      {:ok, bundle} ->
        Bundles.render(bundle, "Bundle created #{bundle.name}")
      {:error, message} ->
        display_error(message)
    end
  end
end

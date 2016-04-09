defmodule Cogctl.Actions.Bundles.Create do
  use Cogctl.Action, "bundles create"

  alias CogApi.HTTP.Client

  @template_extension ".mustache"

  def option_spec do
    [{:file, :undefined, :undefined, {:string, :undefined}, 'Path to your bundle config file (required)'},
     {:templates, :undefined, 'templates', {:string, 'templates'}, 'Path to your template directory'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    config_file = :proplists.get_value(:file, options)
    template_dir = :proplists.get_value(:templates, options)
    do_create(endpoint, config_file, template_dir)
  end

  defp do_create(_endpoint, :undefined, _template_dir),
    do: display_arguments_error
  defp do_create(endpoint, bundle_file, template_dir) do
    results = with {:ok, config}         <- Spanner.Config.Parser.read_from_file(bundle_file),
                   {:ok, templates}      <- build_template_map(template_dir),
                   {:ok, amended_config} <- maybe_add_templates(templates, config),
                   :ok                   <- Spanner.Config.validate(amended_config),
                 do: Client.bundle_create(endpoint, amended_config)

    case results do
      {:ok, bundle} ->
        display_output("Bundle created #{bundle.name}")
      {:error, message} ->
        display_error(message)
    end
  end

  defp build_template_map(template_dir) do
    path = Path.relative_to_cwd(template_dir)
    with {:ok, adapters} <- adapters(path) do
      templates(path, adapters)
    end
  end

  defp adapters(path) do
    if File.dir?(path) do
      adapters = File.ls!(path)
      |> Enum.filter(&File.dir?(Path.join(path, &1)))
      {:ok, adapters}
    else
      {:ok, []}
    end
  end

  defp templates(path, adapters) do
    templates = Enum.reduce(adapters, %{}, fn(adapter, acc) ->
      Path.join(path, adapter)
      |> File.ls!
      |> Enum.filter(&template?/1)
      |> Enum.reduce(acc, &insert_template(&2, Path.join([path, adapter, &1]), adapter))
    end)
    {:ok, templates}
  end

  defp template?(file_name),
    do: String.ends_with?(file_name, @template_extension)

  defp insert_template(map, path, adapter) do
    template_name = Path.basename(path, @template_extension)
    template = File.read!(path)

    if Map.has_key?(map, template_name) do
      put_in(map, [template_name, adapter], template)
    else
      Map.put(map, template_name, %{adapter => template})
    end
  end

  defp maybe_add_templates(external_templates, config) do
    templates = Map.merge(external_templates, Map.get(config, "templates", %{}))
    {:ok, Map.put(config, "templates", templates)}
  end
end

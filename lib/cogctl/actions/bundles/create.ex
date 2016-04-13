defmodule Cogctl.Actions.Bundles.Create do
  use Cogctl.Action, "bundles create"

  alias CogApi.HTTP.Client

  @template_extension ".mustache"

  @moduledoc """
  Creates bundles. The bundles create action creates bundles by taking a bundle
  config file, running some validations on it and POSTing the resulting json.
  Special considerations are made for templates. Templates can be inlined in the
  bundle config or split up into separate files following a specific file hierachy.
  In the later case this action will read each template and append the contents to
  the config file.

  The file hierachy looks as follows:
    templates
    └── <adapter>
        └── <template_name>.mustache

  Your template name should correspond to the command that it belongs to. For example,
  a command called 'date' would have a template called 'date.mustache'

  By default cogctl will look for a directory called 'templates' in the working directory.
  Optionally you can pass a directory via the '--templates' option.
  """

  def option_spec do
    [{:file, :undefined, :undefined, {:string, :undefined}, 'Path to your bundle config file (required)'},
     {:templates, :undefined, 'templates', {:string, 'templates'}, 'Path to your template directory'}]
  end

  def run(options, _args, _config, endpoint) do
    case convert_to_params(options, [file: :required,
                                     templates: :required]) do
      {:ok, params} ->
        with_authentication(endpoint, &do_create(&1, params))
      :error ->
        display_arguments_error
    end
  end

  defp do_create(endpoint, params) do
    results = with {:ok, config}         <- Spanner.Config.Parser.read_from_file(params.file),
                   {:ok, templates}      <- build_template_map(params.templates),
                   {:ok, amended_config} <- maybe_add_templates(templates, config),
                   {:ok, fixed_config}   <- Spanner.Config.validate(amended_config),
                 do: Client.bundle_create(endpoint, fixed_config)

    case results do
      {:ok, bundle} ->
        display_output("Created '#{bundle.name}' bundle")
      {:error, messages} when is_list(messages) ->
        # Map over messages and convert any validation errors
        # into strings so cogctl can display them
        Enum.map(messages, &format_validation_reason/1) |> display_error
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
    # Produces a map like this:
    # %{<template_name> => %{
    #     <adapter> => <template_content>,
    #     <adapter> => <template_content>},
    #   <template_name> => %{
    #     ...}
    #  }
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

  defp format_validation_reason({reason, field_path}) do
    field_path = String.replace(field_path, "#/", "", global: false)
    "Invalid field '#{field_path}': #{reason}"
  end
  defp format_validation_reason(error) do
    error
  end
end

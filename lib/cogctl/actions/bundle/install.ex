defmodule Cogctl.Actions.Bundle.Install do
  use Cogctl.Action, "bundle install"

  alias CogApi.HTTP.Client
  alias Cogctl.Table
  import Cogctl.Actions.Bundle.Helpers, only: [field: 2]

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
    [{:bundle_or_path, :undefined, :undefined, :string, 'Name of registered bundle or local path to bundle config (required). Examples: heroku, bundles/heroku/config.yaml'},
     {:version, :undefined, :undefined, {:string, 'latest'}, 'Version of registered bundle (defaults to the latest version)'},
     {:templates, ?t, 'templates', {:string, 'templates'}, 'Path to your template directory'},
     {:enabled, ?e, 'enable', {:boolean, false}, 'Enable bundle after installing'},
     {:verbose, ?v, 'verbose', {:boolean, false}, 'Verbose output'},
     {:"relay-groups", :undefined, 'relay-groups', {:list, :undefined}, 'List of relay group names separated by commas to assign the bundle'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [:bundle_or_path, :templates, :enabled, :verbose, :"relay-groups", :version])
    with_authentication(endpoint, &do_install(&1, params))
  end

  defp do_install(endpoint, params) do
    case install_bundle(endpoint, params) do
      {:ok, bundle_version} ->
        assign_to_relay_groups(endpoint, bundle_version, params)

        case enable_bundle_version(endpoint, bundle_version, params) do
          :error ->
            render(bundle_version, "Disabled", params)
            display_error("Could not enable bundle.")
          status ->
            render(bundle_version, status, params)
        end

      {:error, messages} when is_list(messages) ->
        # Map over messages and convert any validation errors
        # into strings so cogctl can display them
        Enum.map(messages, &format_validation_error/1) |> display_error
      {:error, error} ->
        display_error(error)
    end
  end

  defp render(bundle_version, status, params) do
    table = Enum.reject(
      [field("Bundle ID:", bundle_version.bundle_id),
       field("Version ID:", bundle_version.id),
       field("Name:", bundle_version.name),
       field("Version:", bundle_version.version),
       field("Status:", status)],
     &is_nil/1)

    Table.format(table)
    |> display_output(params.verbose)
  end

  defp parse_bundle_or_path(params) do
    bundle_or_path = params.bundle_or_path

    cond do
      File.exists?(bundle_or_path) ->
        {:config, Spanner.Config.Parser.read_from_file!(bundle_or_path)}
      match?({:ok, _}, Poison.decode(bundle_or_path)) ->
        {:config, Spanner.Config.Parser.read_from_string!(bundle_or_path)}
      true ->
        bundle = bundle_or_path
        version = params.version
        {:registry, {bundle, version}}
    end
  end

  defp validate_config(config) do
    case Spanner.Config.validate(config) do
      {:ok, validated_config} ->
        {:ok, validated_config}
      {:warning, upgraded_config, warnings} ->
        # If the user passes a config with deprecated fields, we should warn them
        Enum.map(warnings, &format_validation_warning/1) |> display_warning
        {:ok, upgraded_config}
      {:error, errors, warnings} ->
        Enum.map(warnings, &format_validation_warning/1) |> display_warning
        {:error, errors}
    end
  end

  defp install_bundle(endpoint, params) do
    case parse_bundle_or_path(params) do
      {:config, config} ->
        with {:ok, templates}      <- build_template_map(params.templates),
             {:ok, amended_config} <- maybe_add_templates(templates, config),
             {:ok, fixed_config}   <- validate_config(amended_config) do
          params = Map.put(params, "config", fixed_config)
          Client.bundle_install(endpoint, params)
        end
      {:registry, {bundle, version}} ->
        Client.bundle_install_from_registry(endpoint, bundle, version)
    end
  end

  defp assign_to_relay_groups(endpoint, bundle, %{"relay-groups": relay_groups}=params) do
    Enum.map(relay_groups, fn relay_group ->
      result = Client.relay_group_add_bundles_by_name(relay_group, bundle.name, endpoint)

      case result do
        {:ok, relay_group} ->
          message = "Assigned #{bundle.name} bundle to #{relay_group.name} relay group"
          display_output(message, params.verbose)
        {:error, error} ->
          inspect(error)
          |> display_error
      end
    end)
  end

  # Nothing to assign
  defp assign_to_relay_groups(_endpoint, _bundle, _params) do
    []
  end

  defp enable_bundle_version(endpoint, bundle_version, params) do
    if params.enabled do
      case Client.bundle_enable_version(endpoint, bundle_version.bundle_id, bundle_version.id) do
        {:ok, _} ->
          "Enabled"
        {:error, error} ->
          display_error(error)
      end
    else
      "Disabled"
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

  defp format_validation_reason(reason, field_path) do
    String.replace(field_path, "#/", "", global: false)
    "'#{field_path}': #{reason}"
  end

  defp format_validation_error({reason, field_path}) do
    "Invalid field #{format_validation_reason(reason, field_path)}"
  end
  defp format_validation_error(error) do
    error
  end

  defp format_validation_warning({reason, field_path}) do
    format_validation_reason(reason, field_path)
  end
  defp format_validation_warning(warning) do
    warning
  end
end

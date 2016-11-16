defmodule Cogctl.Actions.Bundle.Install do
  use Cogctl.Action, "bundle install"

  alias CogApi.HTTP.Client
  alias Cogctl.Table
  import Cogctl.Actions.Bundle.Helpers, only: [field: 2]

  @template_extensions [".md", ".greenbar"]

  @moduledoc """
  Creates bundles. The bundles create action creates bundles by taking a bundle
  config file, running some validations on it and POSTing the resulting json.
  Special considerations are made for templates. Templates can be inlined in the
  bundle config or split up into separate files. By default cogctl will look for
  a 'templates' directory in the current working directory. Optionally a user can
  specify a path for templates using the --templates switch.

  Template names should correspond to the command that they belong to. For example,
  a command called 'date' would have a template called 'date.greenbar'. Template
  files may use either the '.greenbar' or the '.md' extension.
  """

  def option_spec do
    [{:bundle_or_path, :undefined, :undefined, :string, 'Name of registered bundle or local path to bundle config (required). Examples: heroku, bundles/heroku/config.yaml'},
     {:version, :undefined, :undefined, {:string, 'latest'}, 'Version of registered bundle (defaults to the latest version)'},
     {:templates, ?t, 'templates', {:string, 'templates'}, 'Path to your template directory'},
     {:enabled, ?e, 'enable', {:boolean, false}, 'Enable bundle after installing'},
     {:verbose, ?v, 'verbose', {:boolean, false}, 'Verbose output'},
     {:force, ?f, 'force', {:boolean, false}, 'Force bundle installation even if a bundle with the same version is already installed'},
     {:"relay-groups", :undefined, 'relay-groups', {:list, :undefined}, 'List of relay group names separated by commas to assign the bundle'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [:bundle_or_path, :templates, :enabled, :verbose, :"relay-groups", :version, :force, :stdin])
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

  # If input comes in on stdin then we know that we are dealing with
  # a bundle config string.
  defp parse_bundle_or_path(%{stdin: true}=params) do
    case Spanner.Config.Parser.read_from_string(params.bundle_or_path) do
      {:ok, config} ->
        {:config, config}
      error ->
        error
    end
  end
  # If we aren't getting input on stdin we could be dealing with a
  # config file or the name of a bundle in warehouse.
  defp parse_bundle_or_path(params) do
    bundle_or_path = params.bundle_or_path

    # If a file exists then we parse the config from the file name.
    if File.exists?(bundle_or_path) do
      case Spanner.Config.Parser.read_from_file(bundle_or_path) do
        {:ok, config} ->
          {:config, config}
        error ->
          error
      end
    # Otherwise we assume that the user is specifying a bundle in the
    # registry.
    else
      {:registry, {bundle_or_path, params.version}}
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
        with {:ok, amended_config}  <- add_templates_from_dir(config, params.templates),
             {:ok, valid_config}    <- validate_config(amended_config) do
          Client.bundle_install(endpoint, %{"config" => valid_config, "force" => params[:force]})
        end
      {:registry, {bundle, version}} ->
        Client.bundle_install_from_registry(endpoint, bundle, version)
      {:error, error} ->
        {:error, error}
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

  defp add_templates_from_dir(config, template_dir) do
    path = Path.relative_to_cwd(template_dir)
    if File.dir?(path) do
      templates = File.ls!(path)
      |> Enum.filter(&String.ends_with?(&1, @template_extensions))
      |> Map.new(&({template_name(&1), template_body(path, &1)}))
      |> Map.merge(Map.get(config, "templates", %{}))

      {:ok, put_in(config, ["templates"], templates)}
    else
      {:ok, config}
    end
  end

  defp template_name(template) do
    ext = Path.extname(template)
    Path.basename(template, ext)
  end

  defp template_body(path, filename) do
    %{"body" => read_template!(path, filename)}
  end

  defp read_template!(path, filename) do
    Path.join([path, filename])
    |> File.read!
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

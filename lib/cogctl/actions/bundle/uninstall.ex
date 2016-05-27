defmodule Cogctl.Actions.Bundle.Uninstall do
  use Cogctl.Action, "bundle uninstall"
  alias CogApi.HTTP.Client

  def option_spec do
    [{:bundle_name, :undefined, :undefined, :string, 'Bundle name (required)'},
     {:bundle_version, :undefined, :undefined, {:string, :undefined}, 'Bundle version'},
     {:verbose, ?v, 'verbose', {:boolean, false}, 'Verbose output'},
     {:clean, ?c, 'clean', {:boolean, false}, 'Uninstall all disabled bundle versions'},
     {:all, ?a, 'all', {:boolean, false}, 'Uninstall all versions'}]
  end

  def run(options, args,  _config, endpoint) do
    # The first version is set as an optional positional option so it shows up
    # in the usage blerb. Any additional args are considered additional versions
    # so we put them all together is a version list here.
    versions = case :proplists.get_value(:bundle_version, options) do
      :undefined -> []
      version -> [version] ++ args
    end
    bundle_name = :proplists.get_value(:bundle_name, options)
    verbose = :proplists.get_value(:verbose, options)

    cond do
      :proplists.get_value(:all, options) ->
        with_authentication(endpoint, &uninstall_all(&1, bundle_name, verbose))
      :proplists.get_value(:clean, options) ->
        with_authentication(endpoint, &clean(&1, bundle_name, verbose))
      true ->
        with_authentication(endpoint, &uninstall_versions(&1, bundle_name, versions, verbose))
    end
  end

  defp uninstall_all(endpoint, bundle_name, verbose) do
    # We get the bundle index first so we can check for an enabled version
    # and alert the user appropriately.
    case Client.bundle_version_index_by_name(endpoint, bundle_name) do
      {:ok, [first |_]=bundle_versions} ->
        # Look for any enabled versions
        case Enum.find(bundle_versions, &(&1.enabled)) do
          # If there are no enabled versions, go ahead with the uninstall
          nil ->
            case Client.bundle_uninstall(endpoint, first.bundle_id) do
              :ok ->
                Enum.each(bundle_versions, &display_output("Uninstalled '#{bundle_name}' '#{&1.version}'", verbose))
              {:error, error} ->
                display_error(error)
            end
          # If there is an enabled version alert the user
          bundle_version ->
            display_error("Cannot uninstall an enabled bundle")
            display_warning("Version '#{bundle_version.version}' of '#{bundle_name}' is currently enabled")
        end
      {:error, error} ->
        display_error(error)
    end
  end

  # If the tries to uninstall everything without the '--all' flag, we warn the user
  # and do nothing else.
  defp uninstall_versions(_endpoint, bundle_name, [], _verbose) do
    display_error("Can't uninstall '#{bundle_name}'. You must specify either '--all' or '--clean'.")
    display_warning("This operation is irreversible.")
  end
  defp uninstall_versions(endpoint, bundle_name, version_numbers, verbose) do
    Enum.reduce(version_numbers, :ok, fn(version_number, status) ->
      case Client.bundle_uninstall_version_by_name(endpoint, bundle_name, version_number) do
        :ok ->
          display_output("Uninstalled '#{bundle_name}' '#{version_number}'", verbose)
          status
        {:error, error} ->
          display_error(error)
      end
    end)
  end

  defp clean(endpoint, bundle_name, verbose) do
    case Client.bundle_version_index_by_name(endpoint, bundle_name) do
      {:ok, bundle_versions} ->
        versions_to_clean = Enum.reject(bundle_versions, &(&1.enabled))
        clean(endpoint, bundle_name, versions_to_clean, verbose)
      {:error, error} ->
        display_error(error)
    end
  end

  defp clean(endpoint, bundle_name, versions, verbose) do
    Enum.reduce(versions, :ok, fn(version, status) ->
      case Client.bundle_uninstall_version(endpoint, version.bundle_id, version.id) do
        :ok ->
          display_output("Uninstalled '#{bundle_name}' '#{version.version}'", verbose)
          status
        {:error, error} ->
          display_error(error)
      end
    end)
  end
end

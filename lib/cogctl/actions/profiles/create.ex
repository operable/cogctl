defmodule Cogctl.Actions.Profiles.Create do
  use Cogctl.Action, "profiles create"

  def option_spec, do: []

  def run(_options, [], _config, _endpoint),
    do: display_error("Please provide a name for the profile to create")
  def run(options, [name], config, _endpoint) do
    new_config = extract_config(options)

    new_config = default_config
    |> Map.merge(new_config)
    |> validate_config

    case new_config do
      {:ok, new_config} ->
        save_config(name, new_config, config)
      {:error, error} ->
        display_error(error)
    end
  end

  defp extract_config(options) do
    rest_user     = :proplists.get_value(:rest_user, options)
    rest_password = :proplists.get_value(:rest_password, options)
    host          = :proplists.get_value(:host, options)
    port          = :proplists.get_value(:port, options)
    secure        = :proplists.get_value(:secure, options)

    config = %{"user"     => rest_user,
               "password" => rest_password,
               "host"     => host,
               "port"     => port,
               "secure"   => secure}

    config
    |> Enum.reject(&(elem(&1, 1) == :undefined))
    |> Enum.into(%{})
  end

  defp validate_config(config) do
    required_values = config
    |> Map.take(["user", "password"])
    |> Map.values

    case required_values  do
      [] ->
        {:error, "Must provide --rest-user and --rest-password options"}
      _ ->
        {:ok, config}
    end
  end

  defp save_config(name, new_config, config) do
    config = %{config | dirty: true, values: Map.merge(config.values, %{name => new_config})}
    Cogctl.Config.save(config)
  end

  defp default_config do
    %{"host" =>   "localhost",
      "port" =>   4000,
      "secure" => false}
  end
end

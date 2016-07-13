defmodule Cogctl do

  @default_host "localhost"
  @default_port 4000

  @overrides [{:rest_user, :user},
              {:rest_password, :password},
              {:host, :host},
              {:port, :port},
              {:secure, :secure}]

  defmodule Profile do
    defstruct [:host, :port, :user, :password, :secure]
  end

  def main(args) do
    result = with {handler, options, remaining} <- Cogctl.Optparse.parse(args),
      {:ok, config} <- Cogctl.Config.load(options),
      {:ok, identity} <- configure_identity(options, config),
      do: handler.run(options, remaining, config, identity)

    case result do
      :ok ->
        :ok
      :done ->
        :ok
      :error ->
        exit({:shutdown, 1})
      {:error, msg} ->
        exit_with_error(msg)
      error ->
        exit_with_error("ERROR: #{inspect(error)}")
    end
  end

  defp exit_with_error(error) do
    IO.puts(:stderr, "cogctl: #{error}")
    exit({:shutdown, 1})
  end

  defp configure_identity(options, config) do
    profile = case try_profiles(options, config) do
                nil -> default_profile
                profile -> profile
              end
    profile = apply_overrides(profile, options)
    endpoint = new_endpoint(profile)

    {:ok, endpoint}
  end

  defp new_endpoint(profile=%Cogctl.Profile{}) do
    %CogApi.Endpoint{
      proto: protocol(profile),
      host: profile.host,
      port: profile.port,
      username: profile.user,
      password: profile.password
    }
  end

  defp protocol(%{secure: "true"}), do: "https"
  defp protocol(%{secure: true}),   do: "https"
  defp protocol(_), do: "http"

  defp apply_overrides(profile, options) do
    Enum.reduce(@overrides, profile, fn(mapping, acc) -> maybe_override(mapping, options, acc) end)
  end

  def maybe_override({opt, profile_key}, options, profile) do
    case :proplists.get_value(opt, options) do
      :undefined ->
        profile
      value ->
        Map.put(profile, profile_key, value)
    end
  end

  defp try_profiles(options, config) do
    case :proplists.get_value(:profile, options) do
      :undefined ->
        case get_in(config.values, ["defaults", "profile"]) do
          nil ->
            nil
          profile_name ->
            load_profile(profile_name, config)
        end
      profile_name ->
        load_profile(profile_name, config)
    end
  end

  defp load_profile(name, config) do
    case Map.get(config.values, name) do
      nil ->
        exit_with_error("ERROR: Profile '#{name}' is missing.")
      profile ->
        build_profile(profile)
    end
  end

  defp default_profile do
    %Cogctl.Profile{host: @default_host,
                    port: @default_port}
  end

  defp build_profile(profile) do
    %Cogctl.Profile{host: Map.get(profile, "host", "localhost"),
                    port: Map.get(profile, "port", 4000),
                    user: Map.get(profile, "user"),
                    password: Map.get(profile, "password"),
                    secure: Map.get(profile, "secure", false)}
  end

  def undefined_to_nil(:undefined) do
    nil
  end
  def undefined_to_nil(value) do
    value
  end
end

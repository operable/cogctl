defmodule Cogctl do

  @default_host "localhost"
  @default_port 4000

  defmodule Profile do
    defstruct [:host, :port, :user, :password, :secure]
  end

  def main(args) do
    Application.start(:ibrowse)

    result = with {handler, options, remaining} <- Cogctl.Optparse.parse(args),
      {:ok, config} <- Cogctl.Config.load,
      {:ok, identity} <- configure_identity(options, config),
      do: handler.run(options, remaining, config, identity)

    case result do
      :ok ->
        :ok
      :done ->
        :ok
      :error ->
        exit({:shutdown, 1})
      error ->
        display_error(error)
    end
  end

  defp display_error(error) do
    IO.puts "Error: #{inspect error}"
    exit({:shutdown, 1})
  end

  defp configure_identity(options, config) do
    profile = case try_profiles(options, config) do
                nil -> default_profile
                profile -> profile
              end
    profile = apply_overrides(profile, options)
    client = new_client(profile)

    {:ok, client}
  end

  defp new_client(profile=%Cogctl.Profile{}) do
    %CogApi{
      proto: protocol(profile),
      host: profile.host,
      port: profile.port,
      username: profile.user,
      password: profile.password
    }
  end

  defp protocol(%{secure: "true"}), do: "https"
  defp protocol(%{secure: "false"}), do: "http"

  defp apply_overrides(profile, options) do
    for opt <- Map.keys(profile) do
      if opt != :__struct__ do
        case :proplists.get_value(opt, options) do
          :undefined ->
            :undefined
          value ->
            Map.put(profile, opt, value)
        end
      end
    end

    profile
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
        IO.puts "Profile '#{name}' is missing."
        exit({:shutdown, 1})
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

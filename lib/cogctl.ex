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
    case :proplists.get_value(:host, options) do
      :undefined ->
        case try_profiles(options, config) do
          nil ->
            try_user_options(%Cogctl.Profile{host: @default_host, port: @default_port}, options)
          profile ->
            {:ok, profile}
        end
      host ->
        port = :proplists.get_value(:port, options, @default_port)
        try_user_options(%Cogctl.Profile{host: host, port: port}, options)
    end
  end

  defp try_user_options(profile, options) do
    {:ok, %{profile | user: undefined_to_nil(:proplists.get_value(:user, options)),
                      password: undefined_to_nil(:proplists.get_value(:password, options))}}
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

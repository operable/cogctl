defmodule Cogctl.Actions.Profiles do

  use Cogctl.Action, "profiles"

  def option_spec() do
    []
  end

  def run(_, _, config, _) do
    default = get_in(config.values, ["defaults", "profile"])
    sections = Enum.sort(Map.keys(config.values))
    display_sections(sections, default, config)
  end

  defp display_sections([], _, _) do
    :ok
  end
  defp display_sections(["defaults"|t], default, config) do
    display_sections(t, default, config)
  end
  defp display_sections([name|t], default, %Cogctl.Config{values: values}=config) do
    host = default_value(get_in(values, [name, "host"]), "localhost")
    port = default_value(get_in(values, [name, "port"]), 4000)
    secure = default_value(get_in(values, [name, "secure"]), false)
    user = get_in(values, [name, "user"])
    password = case get_in(values, [name, "password"]) do
                 nil ->
                   "None"
                 _ ->
                   "***"
               end
    output = "Profile: #{name}#{flag_default(name, default)}\n" <>
      "User: #{user}\n" <>
      "Password: #{password}\n" <>
      "URL: #{build_url(host, port, secure)}\n"
    IO.puts output
    display_sections(t, default, config)
  end

  defp flag_default(name, default) when name == default do
    " (default)"
  end
  defp flag_default(_, _), do: ""

  defp build_url(host, port, secure) do
    proto = if secure do
      "https://"
    else
      "http://"
    end
    "#{proto}#{host}:#{port}"
  end

  defp default_value(nil, default), do: default
  defp default_value(value, _), do: value

end

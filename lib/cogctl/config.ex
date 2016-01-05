defmodule Cogctl.Config do

  defstruct [:values, :dirty]

  def load() do
    case File.exists?(config_file) do
      false ->
        {:ok, %__MODULE__{values: %{}, dirty: false}}
      true ->
        case ConfigParser.parse_file(config_file) do
          {:ok, config} ->
            {:ok, %__MODULE__{values: config, dirty: false}}
          error ->
            error
        end
    end
  end

  def save(%__MODULE__{dirty: false}) do
    :ok
  end
  def save(%__MODULE__{values: values}) do
    creating = not(File.exists?(config_file))
    case File.open(config_file(:write), [:write]) do
      {:ok, fd} ->
        case write_values(fd, values, creating) do
          :ok ->
            File.rename(config_file(:write), config_file)
          error ->
            error
        end
      error ->
        error
    end
  end

  defp write_values(fd, values, creating) do
    keys = Map.keys(values)
    write_default_profile(fd, keys, creating)
    sections = Enum.sort(keys)
    write_sections(fd, sections, values)
  end

  defp write_default_profile(_fd, _keys, false) do
    :ok
  end
  defp write_default_profile(fd, [default|_], true) do
    IO.write(fd, "[defaults]\n")
    IO.write(fd, "profile=#{default}\n\n")
  end

  defp write_sections(fd, [], _) do
    File.close(fd)
  end
  defp write_sections(fd, [section|t], values) do
    case IO.write(fd, "[#{section}]\n") do
      :ok ->
        section_values = Map.fetch!(values, section)
        section_keys = Enum.sort(Map.keys(section_values))
        case write_section_values(fd, section_keys, section_values) do
          :ok ->
            write_sections(fd, t, values)
          error ->
            error
        end
      error ->
        error
    end
  end

  defp write_section_values(_, [], _) do
    :ok
  end
  defp write_section_values(fd, [name|t], values) do
    value = Map.fetch!(values, name)
    case IO.write(fd, "#{name}=#{value}\n") do
      :ok ->
        write_section_values(fd, t, values)
      error ->
        error
    end
  end

  defp config_file() do
    config_file(:read)
  end

  defp config_file(:write) do
    Path.join(System.user_home!, ".cogctl.new")
  end
  defp config_file(:read) do
    Path.join(System.user_home!, ".cogctl")
  end

end

defmodule Support.CliHelpers do
  import ExUnit.CaptureIO

  @scratch_dir Path.join([File.cwd!, "test", "scratch"])

  def scratch_dir,
    do: @scratch_dir

  def run("cogctl" <> args) do
    capture_io(fn ->
      capture_io(:stderr, fn ->
        try_run("cogctl" <> args)
      end) |> IO.write
    end)
  end
  def run(_) do
    raise ~s(Commands must start with "cogctl")
  end

  def run_capture_stderr("cogctl" <> args) do
    capture_io(:stderr, fn ->
      capture_io(fn ->
        try_run("cogctl" <> args)
      end)
    end)
  end

  def run_capture_stdio("cogctl" <> args) do
    capture_io(fn ->
      capture_io(:stderr, fn ->
        try_run("cogctl" <> args)
      end)
    end)
  end

  def try_run("cogctl" <> args) do
    try do
      args
      |> String.split
      |> smart_split([])
      |> append_config_file
      |> Cogctl.main
    catch
      _, _ ->
        nil
    end
  end

  def run_no_capture("cogctl" <> args) do
    args
    |> String.split
    |> smart_split([])
    |> append_config_file
    |> Cogctl.main
  end

  def ensure_started do
    case run("cogctl bootstrap") do
      "Already bootstrapped\n" ->
        :ok
      "Bootstrapped\n" ->
        :ok
      response ->
        IO.puts(:stderr, "Error when bootstrapping: #{inspect response}")
        raise "An instance of cog must be running."
    end
  end

  @doc """
  Builds a regex string that replaces whitespace with '\s+'. Useful
  for testing output in a table format. We don't really care how much
  whitespace is between columns, just that the data is correct.
  """
  @spec table_string(String.t) :: Regex.t
  def table_string(str) do
    ~r(#{Regex.replace(~r(\s+), str, "\\s+")})
  end

  defp smart_split([], acc), do: acc
  defp smart_split([head|tail], acc) do
    {start, sub} = check?(head)
    if start do
      sublist = append_it([head|tail], sub)
      substr = Enum.join(sublist, " ")
      tail = tail -- sublist
      smart_split(tail, acc ++[substr])
    else
      smart_split(tail, acc ++[head])
    end
  end

  defp check?(str) do
    {String.contains?(str, ["'", "\""]), []}
  end

  defp append_it([head|tail], acc) do
    if String.ends_with?(head, ["'", "\""]) do
      smart_split(tail, acc ++[remove_quote(head)])
    else
      append_it(tail, acc ++ [remove_quote(head)])
    end
  end

  defp remove_quote(str) do
    if String.contains?(str, "'") do
      String.replace(str, "'", "")
    else
      String.replace(str, "\"", "")
    end
  end

  defp append_config_file([]), do: []
  defp append_config_file(args) do
    args ++ ["--config-file", "#{System.cwd!}/cogctl.conf"]
  end

end

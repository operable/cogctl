defmodule Support.CliCase do
  use ExUnit.CaseTemplate
  import ExUnit.CaptureIO

  using do
    quote do
      import Support.CliCase
    end
  end

  setup do
    ensure_started
  end

  def run("cogctl" <> args) do
    capture_io(fn ->
      capture_io(:stderr, fn ->
        try do
          args
          |> String.split
          |> smart_split([])
          |> Cogctl.main
        catch
          _, _ ->
            nil
        end
      end) |> IO.write
    end)
  end

  def run(_) do
    raise ~s(Commands must start with "cogctl")
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

  defp ensure_started do
    case run("cogctl bootstrap") do
      "ERROR: Already bootstrapped\n" ->
        :ok
      "Bootstrapped\n" ->
        :ok
      response ->
        IO.puts(:stderr, "Error when bootstrapping: #{inspect response}")
        raise "An instance of cog must be running."
    end
  end
end

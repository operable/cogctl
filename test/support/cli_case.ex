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
      try do
        args
        |> String.split
        |> Cogctl.main
      catch
        _, _ ->
          nil
      end
    end)
  end

  def run(_) do
    raise ~s(Commands must start with "cogctl")
  end

  defp ensure_started do
    case run("cogctl bootstrap") do
      "Already bootstrapped\n" ->
        :ok
      _ ->
        raise "An instance of cog must already be running."
    end
  end
end

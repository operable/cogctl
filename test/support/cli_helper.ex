defmodule Support.CliHelper do
  import ExUnit.CaptureIO

  def run("cogctl" <> args) do
    capture_io(fn ->
      args
      |> String.split
      |> Cogctl.main
    end)
  end

  def run(_) do
    raise ~s(Commands must start with "cogctl")
  end
end

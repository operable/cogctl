defmodule Support.CliRecordedCase do
  use ExUnit.CaseTemplate

  @vcr_adapter ExVCR.Adapter.IBrowse

  using do
    quote do
      import Support.CliRecordedCase
      import Support.CliHelpers
      use ExVCR.Mock
    end
  end

  setup context do
    recorder = start_recorder(context)

    on_exit(fn ->
      stop_recorder(recorder)
      cleanup_scratch
    end)
  end

  setup do
    Support.CliHelpers.ensure_started
  end

  # The following recorder functions were adapted from ExVCR's `use_cassette`
  # function which could not be easily used here.
  # This is pretty much copied from the Cog implementation of ExVCR
  def start_recorder(context) do

    fixture = ExVCR.Mock.normalize_fixture("#{casename(context.case)}.#{context.test}")
    recorder = ExVCR.Recorder.start(fixture: fixture, adapter: @vcr_adapter, match_requests_on: [:query, :request_body])

    ExVCR.Mock.mock_methods(recorder, @vcr_adapter)

    recorder
  end

  def stop_recorder(nil), do: nil
  def stop_recorder(recorder) do
    try do
      :meck.unload(@vcr_adapter.module_name)
    after
      ExVCR.Recorder.save(recorder)
    end
  end

  defp cleanup_scratch do
    # Remove the scratch dir when we're finished
    File.rm_rf!(Support.CliHelpers.scratch_dir)
  end

  defp casename(context_case) do
    # We filter out the common bits: elixir, Cogctl, Actions, Test
    # So the fixture names aren't crazy long
    Module.split(context_case)
    |> Enum.filter(&(not Regex.match?(~r/^elixir$|^Cogctl$|^Actions$|^Test$/, &1)))
  end
end

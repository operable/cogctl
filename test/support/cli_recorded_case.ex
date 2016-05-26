defmodule Support.CliRecordedCase do
  use ExUnit.CaseTemplate

  @vcr_adapter ExVCR.Adapter.IBrowse

  using do
    quote do
      import Support.CliRecordedCase
      import Support.CliHelpers
      use ExVCR.Mock, options: [clear_mock: true]

      setup_all do
        use_cassette "bootstrap" do
          Support.CliHelpers.ensure_started
        end
      end

    end
  end

  setup do
    on_exit(fn ->
      cleanup_scratch
    end)
  end

  defp cleanup_scratch do
    # Remove the scratch dir when we're finished
    File.rm_rf!(Support.CliHelpers.scratch_dir)
  end
end

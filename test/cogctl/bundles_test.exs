defmodule Cogctl.Actions.Bundles.Test do
  use Support.CliRecordedCase, async: false

  alias Support.BundleHelpers

  test "installing a bundle" do
    use_cassette "installing_a_bundle" do
      config_path = BundleHelpers.create_config_file("testfoo")

      assert run("cogctl bundle install -v #{config_path}") =~ ~r"""
      Bundle ID:   .*
      Version ID:  .*
      Name:        testfoo
      Version:     0.0.1
      Status:      Disabled
      """

      BundleHelpers.cleanup
    end
  end

  test "force installing a bundle" do
    config_path = BundleHelpers.create_config_file("testfoo")

    use_cassette "force_installing_a_bundle", match_requests_on: [:request_body] do
      # initial install
      assert run("cogctl bundle install -v #{config_path}") =~ ~r"""
      Bundle ID:   .*
      Version ID:  .*
      Name:        testfoo
      Version:     0.0.1
      Status:      Disabled
      """

      # reinstall the same bundle with the force, -f, flag.
      assert run("cogctl bundle install -v --force #{config_path}") =~ ~r"""
      Bundle ID:   .*
      Version ID:  .*
      Name:        testfoo
      Version:     0.0.1
      Status:      Disabled
      """

      BundleHelpers.cleanup
    end
  end

  test "installing a bundle with templates" do
    use_cassette "installing_with_templates", match_requests_on: [:request_body] do
      config_path = BundleHelpers.create_config_file("testfoo")
      templates_path = BundleHelpers.create_templates

      assert run("cogctl bundle install -v --templates #{templates_path} #{config_path}") =~ ~r"""
      Bundle ID:   .*
      Version ID:  .*
      Name:        testfoo
      Version:     0.0.1
      Status:      Disabled
      """

      BundleHelpers.cleanup
    end
  end

  test "installing a bundle with stdin" do
    # We create a config file and split it on newlines
    config = BundleHelpers.create_config_str("stdin_test")

    # We have to mock stdin bits
    {:ok, pid} = StringIO.open(config)
    :meck.new(IO, [:passthrough])
    :meck.expect(IO, :read, fn
                 (:stdio, :line) ->
                   case :meck.passthrough([pid, :line]) do
                     :eof ->
                       # We unload the mock when we get to the end of the file
                       # so we don't conflict with exVCR
                       :meck.unload(IO)
                       :eof
                      data ->
                        data
                   end
                 (device, line) -> :meck.passthrough([device, line])
    end)

    use_cassette "installing_with_stdin", match_requests_on: [:request_body] do
      # assert that we can install a bundle via stdin
      assert run("cogctl bundle install -v -i") =~ ~r"""
        Bundle ID:   .*
        Version ID:  .*
        Name:        stdin_test
        Version:     0.0.1
        Status:      Disabled
        """
    end
  end

  test "uninstalling a bundle" do
    use_cassette "uninstalling_a_bundle" do
      BundleHelpers.create_bundle("foobar")

      assert run("cogctl bundle uninstall foobar --all -v") =~ ~r"""
      Uninstalled 'foobar' '0.0.1'
      """

      BundleHelpers.cleanup
    end
  end

  test "listing bundles" do
    use_cassette "listing_bundles", match_requests_on: [:request_body] do
      BundleHelpers.create_bundle("testbundle")
      BundleHelpers.create_bundle("testbundle1")

      assert run("cogctl bundle") =~ table_string("""
      NAME         ENABLED VERSION
      operable     .*
      testbundle   \\(disabled\\)
      testbundle1  \\(disabled\\)
      """)

      BundleHelpers.cleanup
    end
  end

  test "listing bundles with the verbose flag" do
    use_cassette "listing_bundles_verbose" do
      BundleHelpers.create_bundle("testbundle")

      assert run("cogctl bundle -v") =~ table_string("""
      NAME         ENABLED VERSION         INSTALLED VERSIONS      BUNDLE ID
      operable     [0-9]+\.[0-9]+\.[0-9]+  [0-9]+\.[0-9]+\.[0-9]+  .*
      testbundle   \\(disabled\\)          [0-9]+\.[0-9]+\.[0-9]+  .*
      """)

      BundleHelpers.cleanup
    end
  end

  test "enabling a bundle" do
    use_cassette "enabling_bundle" do
      BundleHelpers.create_bundle("enablebundle")

      assert run("cogctl bundle enable enablebundle -v") =~ ~r"""
      Enabled 'enablebundle' '0.0.1'
      """

      BundleHelpers.cleanup
    end
  end

  test "bundles info returns an error when args are missing" do
    assert run("cogctl bundle info") =~ ~r"""
    Usage: [\s\S]*\
    cogctl: ERROR: Missing required arguments: 'bundle_name'
    """
  end

  test "showing bundle info for the default bundle(operable)" do
    use_cassette "bundle_info_operable" do
      assert run("cogctl bundle info operable") =~ table_string("""
      Bundle ID:        .*
      Version ID:       .*
      Name:             operable
      Versions:         .*
      Status:           Enabled
      Enabled Version:  .*
      Commands:         .*
      Permissions:      .*
      """)
    end
  end
end

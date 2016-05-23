defmodule Cogctl.Actions.Bundles.Test do
  use Support.CliRecordedCase

  alias Support.BundleHelpers

  setup do
    on_exit(fn ->
      BundleHelpers.cleanup
    end)
  end

  test "installing a bundle" do
    config_path = BundleHelpers.create_config_file("testfoo")

    assert run("cogctl bundle install -v #{config_path}") =~ ~r"""
    Bundle ID:   .*
    Version ID:  .*
    Name:        testfoo
    Version:     0.0.1
    Status:      Disabled
    """

    run("cogctl bundle uninstall testfoo --all")
  end

  test "installing a bundle from an old config file" do
    config_path = BundleHelpers.create_old_config_file("oldfoo")

    assert run_capture_stderr("cogctl bundle install #{config_path}") =~ ~r"""
    WARNING: [\s\S]+
    """

    run("cogctl bundle uninstall oldfoo --all")

    assert run_capture_stdio("cogctl bundle install -v #{config_path}") =~ ~r"""
    Bundle ID:   .*
    Version ID:  .*
    Name:        oldfoo
    Version:     0.0.1
    Status:      Disabled
    """

    run("cogctl bundle uninstall oldfoo --all")
  end

  test "installing a bundle with templates" do
    config_path = BundleHelpers.create_config_file("testfoo")
    templates_path = BundleHelpers.create_templates

    assert run("cogctl bundle install -v --templates #{templates_path} #{config_path}") =~ ~r"""
    Bundle ID:   .*
    Version ID:  .*
    Name:        testfoo
    Version:     0.0.1
    Status:      Disabled
    """

    run("cogctl bundle uninstall testfoo")
  end

  test "uninstalling a bundle" do
    BundleHelpers.create_bundle("foobar")

    assert run("cogctl bundle uninstall foobar --all -v") =~ ~r"""
    Uninstalled 'foobar' '0.0.1'
    """
  end

  test "listing bundles" do
    Enum.each(1..3, &BundleHelpers.create_bundle("testbundle#{&1}"))

    assert run("cogctl bundle") =~ table_string("""
    NAME         ENABLED VERSION
    operable     .*
    site         \\(disabled\\)
    testbundle1  \\(disabled\\)
    testbundle2  \\(disabled\\)
    testbundle3  \\(disabled\\)
    """)

    Enum.each(1..3, &run("cogctl bundle uninstall testbundle#{&1} --all"))
  end

  test "listing bundles with the verbose flag" do
    Enum.each(1..3, &BundleHelpers.create_bundle("testbundle#{&1}"))

    assert run("cogctl bundle -v") =~ table_string("""
    NAME         ENABLED VERSION         INSTALLED VERSIONS      BUNDLE ID
    operable     [0-9]+\.[0-9]+\.[0-9]+  [0-9]+\.[0-9]+\.[0-9]+  .*
    site         \\(disabled\\)          [0-9]+\.[0-9]+\.[0-9]+  .*
    testbundle1  \\(disabled\\)          [0-9]+\.[0-9]+\.[0-9]+  .*
    testbundle2  \\(disabled\\)          [0-9]+\.[0-9]+\.[0-9]+  .*
    testbundle3  \\(disabled\\)          [0-9]+\.[0-9]+\.[0-9]+  .*
    """)

    Enum.each(1..3, &run("cogctl bundle uninstall testbundle#{&1} --all"))
  end

  test "bundles info returns an error when args are missing" do
    assert run("cogctl bundle info") =~ ~r"""
    Usage: [\s\S]*\
    cogctl: ERROR: Missing required arguments: 'bundle_name'
    """
  end

  test "showing bundle info for the default bundle(operable)" do
    assert run("cogctl bundle info operable") =~ table_string("""
    Bundle ID:           .*
    Version ID:          .*
    Name:                operable
    Installed Versions:  .*
    Status:              Enabled
    Version:             .*
    Commands:            .*
    Permissions:         .*
    """)
  end
end

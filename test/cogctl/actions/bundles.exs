defmodule Cogctl.Actions.Bundles.Test do
  use Support.CliRecordedCase

  alias Support.BundleHelpers

  setup do
    on_exit(fn ->
      BundleHelpers.cleanup
    end)
  end

  test "creating a bundle" do
    config_path = BundleHelpers.create_config_file("testfoo")

    assert run("cogctl bundles create #{config_path}") =~ ~r"""
    ID         .*
    Name       testfoo
    Status     disabled
    Installed  .*

    Commands
    NAME  ID
    bar   .*
    """
  end

  test "creating a bundle with templates" do
    config_path = BundleHelpers.create_config_file("testfoo")
    templates_path = BundleHelpers.create_templates

    assert run("cogctl bundles create --templates #{templates_path} #{config_path}") =~ ~r"""
    ID         .*
    Name       testfoo
    Status     disabled
    Installed  .*

    Commands
    NAME  ID
    bar   .*
    """
  end

  test "deleting a bundle" do
    BundleHelpers.create_bundle("foobar")

    assert run("cogctl bundles delete foobar") =~ ~r"""
    Deleted foobar
    """
  end

  test "listing bundles" do
    Enum.each(1..3, &BundleHelpers.create_bundle("testbundle#{&1}"))

    assert run("cogctl bundles") =~ table_string("""
    NAME         STATUS    INSTALLED
    operable     enabled   .*
    testbundle1  disabled  .*
    testbundle2  disabled  .*
    testbundle3  disabled  .*
    """)
  end

  test "bundles info returns an error when args are missing" do
    assert run("cogctl bundles info") =~ ~r"""
    ERROR: "Missing required arguments"
    """
  end

  test "showing bundle info for the default bundle(operable)" do
    assert run("cogctl bundles info operable") =~ table_string("""
    ID         .*
    Name       operable
    Status     enabled
    Installed  .*

    Commands
    NAME         ID
    alias        .*
    bundle       .*
    echo         .*
    filter       .*
    greet        .*
    group        .*
    help         .*
    max          .*
    min          .*
    permissions  .*
    raw          .*
    role         .*
    rules        .*
    seed         .*
    sleep        .*
    sort         .*
    sum          .*
    table        .*
    thorn        .*
    unique       .*
    wc           .*
    which        .*
    """)
  end
end

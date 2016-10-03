defmodule Cogctl.OptParse.Test do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import ExUnit.Assertions

  alias Cogctl.Optparse

  @standard_options [:help,
                     :host,
                     :stdin,
                     :port,
                     :secure,
                     :rest_user,
                     :rest_password,
                     :config_file,
                     :profile]

  @default_options [config_file: Cogctl.Config.default_config_file]

  defp parse(str) do
    String.split(str)
    |> Optparse.parse
  end

  # Gobles up the results of parse, use ExUnit.Assertions.assert_received/1
  # if you want to verify the return of parse/1
  defp capture_parse(str, device \\ :stderr) do
    capture_io(device, fn ->
      send(self(), parse(str))
    end)
  end

  test "returns usage when no command is passed" do
    assert capture_parse("") =~ ~r(Usage: cogctl\t\[.*)
  end

  test "parses commands with no options" do
    {handler, options, args} = parse("relay-groups")
    {_, options} = :proplists.split(options, @standard_options)

    assert handler == Cogctl.Actions.RelayGroups
    assert options == []
    assert args == []
  end

  test "config_file defaults to ~/.cogctl" do
    {handler, options, args} = parse("relay-groups")
    config_file = :proplists.get_value(:config_file, options)
    {_, split_options} = :proplists.split(options, @standard_options)

    assert config_file == Cogctl.Config.default_config_file
    assert handler == Cogctl.Actions.RelayGroups
    assert split_options == []
    assert args == []
  end

  test "config_file defaults to $COGCTL_CONFIG_FILE if set" do
    {handler, options, args} = parse("relay-groups")
    config_file = :proplists.get_value(:config_file, options)
    {_, split_options} = :proplists.split(options, @standard_options)

    assert config_file == "#{System.get_env("HOME")}/.cogctl"
    assert handler == Cogctl.Actions.RelayGroups
    assert split_options == []
    assert args == []
  end

  test "parses commands with options" do
    {handler, options, args} = parse("bundle install my_config.yaml --templates my_templates --enable")
    bundle_or_path = :proplists.get_value(:bundle_or_path, options)
    templates = :proplists.get_value(:templates, options)
    enabled = :proplists.get_value(:enabled, options)
    relay_groups = :proplists.get_value(:"relay-groups", options)

    assert handler == Cogctl.Actions.Bundle.Install
    assert bundle_or_path == "my_config.yaml"
    assert templates == "my_templates"
    assert enabled == true
    assert relay_groups == []
    assert args == []
  end

  test "fails when required args aren't passed" do
    # We test to see if "bundles create" prints usage info
    assert capture_parse("bundle install") =~ ~r(Usage: .*)
    # Then we check to see if it returns the correct value
    assert_received {:error, "ERROR: Missing required arguments: 'bundle_or_path'"}
  end

  test "lists are returned as elixir lists" do
    {handler, options, args} = parse("relay-groups create foo --members bar,biz,baz")
    members = :proplists.get_value(:members, options)
    name = :proplists.get_value(:name, options)

    assert handler == Cogctl.Actions.RelayGroups.Create
    assert members == ["bar", "biz", "baz"]
    assert name == "foo"
    assert args == []
  end

  test "extra args are returned" do
    {handler, options, args} = parse("relay-groups delete foo biz baz buz")
    {_, options} = :proplists.split(options, @standard_options)

    assert handler == Cogctl.Actions.RelayGroups.Delete
    assert options == []
    assert args == ["foo", "biz", "baz", "buz"]
  end

  test "exit gracefully when invalid options are passed" do
    assert capture_parse("relays create --bar") =~ ~r(Usage: .*)
    assert_received {:error, "ERROR: Unknown option: '--bar'"}
  end

  test "exit with a suggestion when an unknown command is passed" do
    assert parse("boostrap") == {:error, "Unknown action in 'boostrap'. Did you mean 'bootstrap'?"}
  end
end

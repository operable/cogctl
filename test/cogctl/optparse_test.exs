defmodule Cogctl.OptParse.Test do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import ExUnit.Assertions

  alias Cogctl.Optparse

  @standard_options [:help,
                     :host,
                     :port,
                     :secure,
                     :rest_user,
                     :rest_password,
                     :profile]

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
    {handler, options, args} = parse("bundles")
    {_, options} = Keyword.split(options, @standard_options)

    assert handler == Cogctl.Actions.Bundles
    assert options == []
    assert args == []
  end

  test "parses commands with options" do
    {handler, options, args} = parse("bundles create my_config.yaml --templates my_templates --enable")
    {_, options} = Keyword.split(options, @standard_options)

    assert handler == Cogctl.Actions.Bundles.Create
    assert options == [file: "my_config.yaml", templates: "my_templates", enabled: true, "relay-groups": []]
    assert args == []
  end

  test "fails when required args aren't passed" do
    # We test to see if "bundles create" prints usage info
    assert capture_parse("bundles create") =~ ~r(Usage: .*)
    # Then we check to see if it returns the correct value
    assert_received {:error, "ERROR: Missing required arguments: 'file'"}
  end

  test "lists are returned as elixir lists" do
    {handler, options, args} = parse("relay-groups create foo --members bar,biz,baz")
    {_, options} = Keyword.split(options, @standard_options)

    assert handler == Cogctl.Actions.RelayGroups.Create
    assert options == [name: "foo", members: ["bar", "biz", "baz"]]
    assert args == []
  end

  test "extra args are returned" do
    {handler, options, args} = parse("bundles delete foo biz baz buz")
    {_, options} = Keyword.split(options, @standard_options)

    assert handler == Cogctl.Actions.Bundles.Delete
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

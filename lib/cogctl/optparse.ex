defmodule Cogctl.Optparse do

  @valid_actions [Cogctl.Actions.Bootstrap,
                  Cogctl.Actions.Profiles,
                  Cogctl.Actions.Bundles,
                  Cogctl.Actions.Bundles.Info,
                  Cogctl.Actions.BundleDelete,
                  Cogctl.Actions.Users,
                  Cogctl.Actions.Users.Info,
                  Cogctl.Actions.Users.Create,
                  Cogctl.Actions.Users.Update,
                  Cogctl.Actions.Users.Delete,
                  Cogctl.Actions.Groups,
                  Cogctl.Actions.Groups.Info,
                  Cogctl.Actions.Groups.Create,
                  Cogctl.Actions.Groups.Update,
                  Cogctl.Actions.Groups.Delete,
                  Cogctl.Actions.Groups.Add,
                  Cogctl.Actions.Groups.Remove,
                  Cogctl.Actions.Roles,
                  Cogctl.Actions.Roles.Create,
                  Cogctl.Actions.Roles.Update,
                  Cogctl.Actions.Roles.Delete,
                  Cogctl.Actions.Roles.Grant,
                  Cogctl.Actions.Roles.Revoke,
                  Cogctl.Actions.Permissions,
                  Cogctl.Actions.Permissions.Create,
                  Cogctl.Actions.Permissions.Delete,
                  Cogctl.Actions.Permissions.Grant,
                  Cogctl.Actions.Permissions.Revoke]

  def parse([arg]) when arg in ["--help", "-?"] do
    parse(nil)
  end
  def parse(args) when length(args) > 0 do
    case parse_action(args) do
      :nil ->
        IO.puts "Unable to parse '#{Enum.join(args, " ")}'"
        exit({:shutdown, 1})
      {handler, other_args} ->
        other_args = Enum.map(other_args, &String.to_char_list(&1))
        {name, specs} = opt_specs(handler)
        {:ok, {options, remaining}} = :getopt.parse(specs, other_args)
        case Enum.member?(options, :help) do
          true ->
            :getopt.usage(specs, name)
            :done
          false ->
            {handler, ensure_elixir_strings(options), ensure_elixir_strings(remaining)}
        end
    end
  end
  def parse(_) do
    actions = Enum.join(display_valid_actions, " | ")
    IO.puts "Usage: cogctl [#{actions}]"
    IO.puts "\n       cogctl <action> --help will display action specific help information."
    :done
  end

  defp parse_action(args) do
    handlers = handler_patterns()
    Enum.reduce(handlers, nil,
      fn(%{handler: handler, pattern: pattern}, nil) ->
        if starts_with?(args, pattern) do
          {handler, args -- pattern}
        else
          nil
        end
        (_handler, accum) -> accum
      end)
  end

  defp handler_patterns() do
    handlers = for handler <- @valid_actions do
      %{handler: handler, pattern: handler.name()}
    end
    Enum.sort(handlers, &(length(&1.pattern) > length(&2.pattern)))
  end

  defp display_valid_actions() do
    for handler <- @valid_actions do
      handler.display_name()
    end
  end

  defp opt_specs(handler) do
    name = String.to_char_list("cogctl " <> handler.display_name())
    specs = handler.option_spec()
    {name, global_opts(specs)}
  end

  defp global_opts(opts) do
    opts ++ [{:help, ??, 'help', :undefined, 'Displays this brief help'},
     {:host, ?h, 'host', {:string, 'localhost'}, 'Host name or network address of the target Cog instance'},
     {:port, ?p, 'port', {:integer, 4000}, 'REST API port of the target Cog instances'},
     {:user, ?u, 'user', :undefined, 'REST API user'},
     {:password, :undefined, 'pw', :undefined, 'REST API password'},
     {:profile, :undefined, 'profile', {:string, :undefined}, '$HOME/.cogctl profile to use'}]
  end
  defp ensure_elixir_strings(items) do
    ensure_elixir_strings(items, [])
  end

  defp ensure_elixir_strings([], accum) do
    Enum.reverse(accum)
  end
  defp ensure_elixir_strings([h|t], accum) when is_list(h) do
    ensure_elixir_strings(t, [String.Chars.List.to_string(h)|accum])
  end
  defp ensure_elixir_strings([{name, value}|t], accum) when is_list(value) do
    ensure_elixir_strings(t, [{name, String.Chars.List.to_string(value)}|accum])
  end
  defp ensure_elixir_strings([h|t], accum) do
    ensure_elixir_strings(t, [h|accum])
  end

  def starts_with?([data|dt], [pattern|pt]) when data == pattern do
    starts_with?(dt, pt)
  end
  def starts_with?(_data, []) do
    true
  end
  def starts_with?(_, _) do
    false
  end

end

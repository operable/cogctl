defmodule Cogctl.Optparse do

  @valid_actions [Cogctl.Actions.Bootstrap,
                  Cogctl.Actions.Profiles]

  def parse([action|args]) do
    case parse_action(action) do
      :nil ->
        IO.puts "Unknown action '#{action}'"
        exit({:shutdown, 1})
      handler ->
        args = Enum.map(args, &String.to_char_list(&1))
        {name, specs} = opt_specs(handler)
        {:ok, {options, remaining}} = :getopt.parse(specs, args)
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
    actions = Enum.join(valid_actions, " | ")
    IO.puts "Usage: cogctl [#{actions}]"
    IO.puts "\n       cogctl <action> --help will display action specific help information."
    :done
  end

  defp parse_action(action) do
    Enum.reduce(@valid_actions, nil,
      fn(handler, accum) -> if handler.name() == action do
                              handler
                            else
                              accum
                            end end)
  end

  defp valid_actions() do
    for handler <- @valid_actions do
      handler.name()
    end
  end

  defp opt_specs(handler) do
    name = String.to_char_list("cogctl " <> handler.name())
    specs = handler.option_spec()
    {name, global_opts(specs)}
  end

  defp global_opts(opts) do
    [{:help, ??, 'help', :undefined, 'Displays this brief help'},
     {:host, ?h, 'host', {:string, 'localhost'}, 'Host name or network address of the target Cog instance'},
     {:port, ?p, 'port', {:integer, 4000}, 'REST API port of the target Cog instances'},
     {:user, ?u, 'user', :undefined, 'REST API user'},
     {:password, :undefined, 'pw', :undefined, 'REST API password'},
     {:profile, :undefined, 'profile', {:string, :undefined}, '$HOME/.cogctl profile to use'}] ++ opts
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

end

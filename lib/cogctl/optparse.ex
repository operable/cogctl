defmodule Cogctl.Optparse do
  @moduledoc """
  Parses command args and options.
  """

  @valid_actions [Cogctl.Actions.Bootstrap,
                  Cogctl.Actions.Profiles,
                  Cogctl.Actions.Bundles,
                  Cogctl.Actions.Bundles.Info,
                  Cogctl.Actions.Bundles.Create,
                  Cogctl.Actions.Bundles.Delete,
                  Cogctl.Actions.Bundles.Enable,
                  Cogctl.Actions.Bundles.Disable,
                  Cogctl.Actions.Users,
                  Cogctl.Actions.Users.Info,
                  Cogctl.Actions.Users.Create,
                  Cogctl.Actions.Users.Update,
                  Cogctl.Actions.Users.Delete,
                  Cogctl.Actions.Groups,
                  Cogctl.Actions.Groups.Info,
                  Cogctl.Actions.Groups.Create,
                  Cogctl.Actions.Groups.Rename,
                  Cogctl.Actions.Groups.Delete,
                  Cogctl.Actions.Groups.Add,
                  Cogctl.Actions.Groups.Remove,
                  Cogctl.Actions.Relays,
                  Cogctl.Actions.Relays.Info,
                  Cogctl.Actions.Relays.Create,
                  Cogctl.Actions.Relays.Enable,
                  Cogctl.Actions.Relays.Disable,
                  Cogctl.Actions.Relays.Update,
                  Cogctl.Actions.Relays.Delete,
                  Cogctl.Actions.RelayGroups,
                  Cogctl.Actions.RelayGroups.Info,
                  Cogctl.Actions.RelayGroups.Create,
                  Cogctl.Actions.RelayGroups.Add,
                  Cogctl.Actions.RelayGroups.Remove,
                  Cogctl.Actions.RelayGroups.Assign,
                  Cogctl.Actions.RelayGroups.Unassign,
                  Cogctl.Actions.RelayGroups.Delete,
                  Cogctl.Actions.Roles,
                  Cogctl.Actions.Roles.Info,
                  Cogctl.Actions.Roles.Create,
                  Cogctl.Actions.Roles.Rename,
                  Cogctl.Actions.Roles.Delete,
                  Cogctl.Actions.Roles.Grant,
                  Cogctl.Actions.Roles.Revoke,
                  Cogctl.Actions.Rules,
                  Cogctl.Actions.Rules.Create,
                  Cogctl.Actions.Rules.Delete,
                  Cogctl.Actions.Permissions,
                  Cogctl.Actions.Permissions.Create,
                  Cogctl.Actions.Permissions.Delete,
                  Cogctl.Actions.Permissions.Grant,
                  Cogctl.Actions.Permissions.Revoke,

                  Cogctl.Actions.Triggers,
                  Cogctl.Actions.Triggers.Create,
                  Cogctl.Actions.Triggers.Delete,
                  Cogctl.Actions.Triggers.Disable,
                  Cogctl.Actions.Triggers.Enable,
                  Cogctl.Actions.Triggers.Info,
                  Cogctl.Actions.Triggers.Update,

                  Cogctl.Actions.ChatHandles,
                  Cogctl.Actions.ChatHandles.Create,
                  Cogctl.Actions.ChatHandles.Delete]

  def action_display_names() do
    for handler <- @valid_actions do
      handler.display_name()
    end
  end

  @doc """
  Parses command invocation. If required args, as defined in the action's
  module, are missing, then we exit with an error. If we get a help flag,
  we display usage info and return ':done'. Otherwise we return the handler
  along with it's options and remaining args.
  """
  @spec parse([String.t]) :: {module(), Keyword.t, [String.t]} | :done | {:error, String.t} | :error
  def parse([action_str]) when action_str in ["--help", "-?"] do
    parse(:help)
  end
  def parse(action_str) when length(action_str) > 0 do
    with {:ok, handler, args} <- parse_action(action_str) do
      case parse_args(handler, args) do
        :help ->
          show_usage(handler)
          :done
        {:error, {:missing_required_options, missing}} ->
          show_usage(handler, :stderr)
          {:error, "ERROR: Missing required arguments: '#{Enum.join(missing, ", ")}'"}
        {:error, {:invalid_option, invalid_option_name}} ->
          show_usage(handler, :stderr)
          {:error, "ERROR: Unknown option: '#{invalid_option_name}'"}
        {options, remaining_args} ->
          {handler, options, remaining_args}
        error ->
          {:error, inspect(error)}
      end
    end
  end
  # Get's triggered when a user explicitly requests help from the root command
  # For example: 'cogctl --help'
  def parse(:help) do
    show_usage(:root)
    :done
  end
  # Get's triggered when a user passes no arguments
  def parse(_) do
    show_usage(:root, :stderr)
    :error
  end

  defp parse_args(handler, args) do
    specs = opt_specs(handler)
    case :getopt.parse(specs, args) do
      {:ok, {options, remaining}} ->
        if show_help?(options) do
          :help
        else
          check(specs, {options, remaining})
        end
      error ->
        error
    end
  end

  defp check(specs, {options, remaining}) do
    case :getopt.check(specs, options) do
      :ok ->
        cast(specs, {options, remaining})
      error ->
        error
    end
  end

  defp cast(specs, {options, remaining}) do
    options = ensure_elixir_strings(options)
    remaining = ensure_elixir_strings(remaining)
    cast_options = Enum.reduce(specs, options, fn
      ({name, _short, _long, type, _desc}, options) ->
        type = get_type(type)
        case :proplists.get_value(name, options, nil) do
          nil ->
            options
          value ->
            new_value = cast(type, value)
            updated = [{name, new_value}] ++ :proplists.delete(name, options)
        end
      (_, options) ->
        options
    end)
    {cast_options, remaining}
  end

  defp cast(:list, value) when is_list(value),
    do: value
  defp cast(:list, :undefined),
    do: []
  defp cast(:list, value) when is_binary(value) do
    String.split(value, ",")
    |> Enum.reject(&(String.length(&1) == 0))
  end
  defp cast(_type, value),
    do: value

  defp handler_name(handler) do
    String.to_char_list("cogctl " <> handler.display_name())
  end

  defp show_help?(options),
    do: Keyword.get(options, :help, false)

  defp show_usage(handler, output_stream \\ :stdio),
    do: do_show_usage(handler, output_stream)

  defp do_show_usage(:root, output_stream) do
    actions = format_actions(action_display_names)
    IO.puts output_stream, "Usage: cogctl\t[#{actions}]"
    IO.puts output_stream, ""
    IO.puts output_stream, "       cogctl <action> --help will display action specific help information."
  end
  defp do_show_usage(handler, output_stream) do
    output_stream = case output_stream do
      :stdio -> :standard_io
      :stderr -> :standard_error
    end
    :getopt.usage(opt_specs(handler), handler_name(handler), output_stream)
  end

  # Returns the type from the option spec
  defp get_type({type, _default}),
    do: type
  defp get_type(type),
    do: type

  defp parse_action(args) do
    handlers = handler_patterns()
    result = Enum.reduce(handlers, :unknown_action,
      fn(%{handler: handler, pattern: pattern}, :unknown_action) ->
        if starts_with?(args, pattern) do
          remaining_args = Enum.map(args -- pattern, &String.to_char_list(&1))
          {:ok, handler, remaining_args}
        else
          :unknown_action
        end
        (_handler, accum) -> accum
      end)

    case result do
      {:ok, handler, remaining_args} ->
        {:ok, handler, remaining_args}
      :unknown_action ->
        suggestion = get_suggestion(handlers, args)
        {:error, "Unknown action in '#{Enum.join(args, " ")}'. Did you mean '#{suggestion}'?"}
    end
  end

  defp get_suggestion(handlers, args) do
    action = Enum.join(args, " ")
    Enum.map(handlers, &Enum.join(Map.get(&1, :pattern), " "))
    |> Enum.max_by(&String.jaro_distance(&1, action))
  end

  defp handler_patterns() do
    handlers = for handler <- @valid_actions do
      %{handler: handler, pattern: handler.name()}
    end
    Enum.sort(handlers, &(length(&1.pattern) > length(&2.pattern)))
  end

  defp opt_specs(handler) do
    handler.option_spec()
    |> global_opts
  end

  defp global_opts(opts) do
    opts ++ [{:help, ??, 'help', {:boolean, false}, 'Displays this brief help'},
     {:host, ?h, 'host', {:string, :undefined}, 'Host name or network address of the target Cog instance'},
     {:port, ?p, 'port', {:integer, :undefined}, 'REST API port of the target Cog instances'},
     {:secure, ?s, 'secure', {:boolean, false}, 'Use HTTPS to connect to Cog'},
     {:rest_user, ?U, 'rest-user', {:string, :undefined}, 'REST API user'},
     {:rest_password, ?P, 'rest-password', {:string, :undefined}, 'REST API password'},
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

  defp format_actions(names) do
    format_actions(names, 0, [])
  end

  defp format_actions([], _, accum) do
    [_|accum] = Enum.reverse(accum)
    Enum.join(accum, "")
  end
  defp format_actions([name|t], 5, accum) do
    format_actions(t, 0, [name, " |\n\t\t"|accum])
  end
  defp format_actions([name|t], n, accum) do
    format_actions(t, n + 1, [name, " | "|accum])
  end
end

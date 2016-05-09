defmodule Cogctl.ActionUtil do

  @doc """
  Returns a structure with the field named `opt_key` set to
  the value with the same key from the proplist that is passed
  in as opts. If the value looked up from `opts` is `:undefined`
  it is returned directly instead of the struct.
  """
  def option_to_struct(opts, opt_key, struct) do
    option_to_struct(opts, opt_key, struct, opt_key)
  end

  @doc """
  Returns a structure with the field named `field` set to
  the value from the opts proplist at `opt_key`. If the
  value looked up from `opts` is `:undefined` it is returned
  directly instead of the struct.
  """
  def option_to_struct(opts, opt_key, struct, field) do
    case :proplists.get_value(opt_key, opts) do
      :undefined ->
        :undefined
      value ->
        Map.put(struct, field, value)
    end
  end

  @doc """
  Returns a map containing the key/value pairs of the
  parameters for a command.
  """
  @spec convert_to_params([{atom(), any()}]) :: Map.t
  def convert_to_params(options) do
    Enum.reject(options, fn
      ({_, nil}) -> true
      ({_, :undefined}) -> true
      ({_, ""}) -> true
      (_) -> false
    end)
    |> Enum.into(%{})
  end

  @doc """
  Wraps an operation with a call to authenticate against the Cog
  API. The resulting endpoint (ensured to have a token) will be passed
  to an arity-1 function that will perform the desired action.

  Any authentication-related error is handled for you; errors that
  arise within the execution of your function are your
  responsibility. Authentication errors result in a message being
  printed to `STDERR`.

  The `api` argument is solely for plugging alternative API
  implementations for testing purposes, and generally isn't useful
  outside of that context.
  """
  @spec with_authentication(%CogApi.Endpoint{}, (%CogApi.Endpoint{} -> term), module) :: term
  def with_authentication(endpoint, fun, api \\ CogApi.HTTP.Client) do
    case api.authenticate(endpoint) do
      {:ok, endpoint_with_token} ->
        fun.(endpoint_with_token)
      {:error, error} ->
        IO.puts(:stderr, """
        Unable to authenticate with Cog API:
        #{format_error(error)}

        You can specify appropriate credentials on the command line via
        the `--rest-user` and `--rest-password` flags, or set them in
        your `$HOME/.cogctl` file.
        """)

        :error
    end
  end

  def display_output(output) do
    IO.puts(output)
    :ok
  end

  def display_warning(warnings) when is_list(warnings) do
    Enum.map(warnings, &display_warning/1)
    :ok
  end
  def display_warning(warning) do
    IO.puts(:stderr, "WARNING: #{inspect warning}")
    :ok
  end

  def display_error(errors) when is_list(errors) do
    Enum.map(errors, &display_error/1)
    :error
  end
  def display_error(error) do
    IO.puts(:stderr, "ERROR: #{inspect error}")
    :error
  end

  def display_arguments_error,
    do: display_error("Missing required arguments")

  def display_arguments_error(missing_args) when is_list(missing_args),
    do: display_error("Missing required arguments: '#{Enum.join(missing_args, ",")}'")
  def display_arguments_error(missing_arg),
    do: display_error("Missing required argument: '#{missing_arg}'")

  defp format_error(%{"errors" => errors}), do: format_error(errors)
  defp format_error(error) when is_list(error), do: Enum.join(error, "\n")
  defp format_error(error), do: inspect(error)

end

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
  parameters that are expected for a command. The map is
  built using the options entered and a list of which
  options are required and which are optional.
  """
  def convert_to_params(options, whitelist) do
    params = Keyword.take(options, Keyword.keys(whitelist))

    # Check if any required params are undefined
    missing_params = Enum.filter(params, fn
      ({key, :undefined}) ->
        case Keyword.get(whitelist, key, :optional) do
          :required ->
            true
          :optional ->
            false
        end
      (_) -> false
    end)

    case missing_params do
      [] ->
        params = params
                  |> Enum.reject(&match?({_, :undefined}, &1))
                  |> Enum.into(%{})

        {:ok, params}
      missing ->
        missing_keys = Enum.map(missing, fn({key, _}) -> key end)
        {:error, {:missing_params, missing_keys}}
    end
  end

  @doc """
  Returns a map containing the key/value pairs of the
  parameters that are expected for a command. The map is
  built using the options entered and a list of which
  options are required, which are optional, and the
  specifications for each parameter. The spec denotes
  if a list, integer, float, or string are expected and
  formats the entered value as such.
  """
  def convert_to_params(options, opt_spec, whitelist) do
    structure_options(options, opt_spec)
    |> convert_to_params(whitelist)
  end

  defp structure_options(options, opt_spec) do
    format_spec = Enum.map(opt_spec, fn({key, _, _, {format, _}, _}) ->
      {key, format}
    end)
    Enum.into(options, [], fn({key, value}) ->
      case {value, Keyword.get(format_spec, key)} do
        {:undefined, _} -> {key, value}
        {_, :list} -> {key, String.split(value, ",")}
        {_, :integer} -> {key, String.to_integer(value)}
        {_, :float} -> {key, String.to_float(value)}
        _ -> {key, value}
      end
    end)
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

  def display_error(errors) when is_list(errors) do 
    "ERROR: " <> Enum.join(errors, "\n")
    |> IO.puts
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

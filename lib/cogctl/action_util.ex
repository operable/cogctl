defmodule Cogctl.ActionUtil do
  def convert_to_params(options, whitelist) do
    params = Keyword.take(options, Keyword.keys(whitelist))

    # Check if any required params are undefined
    invalid = Enum.any?(params, fn
      {key, :undefined} ->
        case Keyword.get(whitelist, key, :optional) do
          :required ->
            true
          :optional ->
            false
        end
      _ ->
        false
    end)

    case invalid do
      true ->
        :error
      false ->
        params = params
                  |> Enum.reject(&match?({_, :undefined}, &1))
                  |> Enum.into(%{})

        {:ok, params}
    end
  end

  @doc """
  Wraps an operation with a call to authenticate against the Cog
  API. The resulting client (ensured to have a token) will be passed
  to an arity-1 function that will perform the desired action.

  Any authentication-related error is handled for you; errors that
  arise within the execution of your function are your
  responsibility. Authentication errors result in a message being
  printed to `STDERR`.

  The `api` argument is solely for plugging alternative API
  implementations for testing purposes, and generally isn't useful
  outside of that context.
  """
  @spec with_authentication(%Cogctl.Profile{}, (%Cogctl.Profile{} -> term), module) :: term
  def with_authentication(client, fun, api \\ CogApi) do
    case api.authenticate(client) do
      {:ok, client_with_token} ->
        fun.(client_with_token)
      {:error, error} ->
        IO.puts(:stderr, """
        #{error["error"]}

        You can specify appropriate credentials on the command line via
        the `--user` and `--pw` flags, or set them in your `$HOME/.cogctl`
        file.
        """)
        :error
    end
  end

  def display_output(output) do
    IO.puts(output)
    :ok
  end

  def display_error(error) do
    IO.puts(:stderr, "ERROR: #{error}")
    :error
  end

  def display_arguments_error do
    display_error("Missing required arguments")
  end
end

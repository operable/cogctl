defmodule Cogctl.Action do

  @type parsed_options() :: [{atom(), term()}] | []
  @type remaining_args() :: [String.t()] | []

  @callback name() ::  String.t()

  @callback option_spec() :: [:optparse.option_spec()]

  @callback run(parsed_options(), remaining_args(), %Cogctl.Config{}, %Cogctl.Profile{}) :: :ok | {:error, term()} | :error

  defmacro __using__(name) when name != nil do
    pattern = String.split(name, " ")
    quote do
      @behaviour unquote(__MODULE__)

      def name(), do: unquote(pattern)
      def display_name, do: unquote(name)

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
  end

end

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

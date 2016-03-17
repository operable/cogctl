defmodule Cogctl.Action do

  @type parsed_options() :: [{atom(), term()}] | []
  @type remaining_args() :: [String.t()] | []

  @callback name() ::  String.t()

  @callback option_spec() :: [:optparse.option_spec()]

  @callback run(parsed_options(), remaining_args(), %Cogctl.Config{}, %Cogctl.Profile{}) :: :ok | {:errors, term()} | :error

  defmacro __using__(name) when name != nil do
    pattern = String.split(name, " ")
    quote do
      import Cogctl.ActionUtil

      @behaviour unquote(__MODULE__)

      def name(), do: unquote(pattern)
      def display_name, do: unquote(name)
    end
  end

end

defmodule Cogctl do

  def main(args) do
    case Cogctl.Optparse.parse(args) do
      :done ->
        :ok
      {action, options, remaining} ->
        case execute_action(action, options, remaining) do
          :ok ->
            :ok
          :error ->
            exit({:shutdown, 1})
        end
      error ->
        IO.puts "#{inspect error}"
    end
  end

  defp execute_action("bootstrap", options, _) do
    node = :proplists.get_value(:node, options)
    if Enum.member?(options, :status) do
      Cogctl.Bootstrap.query(node)
    else
      Cogctl.Bootstrap.apply(node)
    end
  end

end

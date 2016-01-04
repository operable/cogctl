defmodule Cogctl.Util do

  def enum_to_set(items) do
    Enum.reduce(items, MapSet.new(), &MapSet.put(&2, &1))
  end

end

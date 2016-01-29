defmodule Cogctl.ActionUtilTest do
  use ExUnit.Case

  alias Cogctl.ActionUtil

  test "converting valid options to params" do
    params = ActionUtil.convert_to_params([a: :undefined, b: true, c: false], [b: :required, c: :optional])
    assert params == {:ok, %{b: true, c: false}}
  end

  test "converting missing required options to params" do
    params = ActionUtil.convert_to_params([a: true, b: :undefined, c: false], [b: :required, c: :optional])
    assert params == :error
  end
end

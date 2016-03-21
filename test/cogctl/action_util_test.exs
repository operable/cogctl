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

  test "with_authentication runs function when authentication succeeds" do
    defmodule AuthEveryone do
      def authenticate(client),
        do: {:ok, client}
    end
    me = self()
    result = ActionUtil.with_authentication(:my_client,
      fn(:my_client) ->
        send(me, :function_ran)
        :success
      end,
      AuthEveryone)

    assert result == :success
    assert_receive :function_ran
  end

  test "with_authentication returns error without running callback when authentication fails" do
    defmodule RejectEveryone do
      def authenticate(_client),
        do: {:error, %{"error" => "nope"}}
    end

    me = self()
    result = ActionUtil.with_authentication(:my_client,
      fn(:my_client) ->
        send(me, :function_ran)
      end,
      RejectEveryone)

    assert result == :error
    refute_receive :function_ran
  end

end

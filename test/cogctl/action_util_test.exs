defmodule Cogctl.ActionUtilTest do
  use ExUnit.Case

  alias Cogctl.ActionUtil

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
        do: {:error, %{"errors" => "nope"}}
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

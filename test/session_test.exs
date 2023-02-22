defmodule SessionTest do
  use ExUnit.Case

  test "assert non-existent session for user" do
    assert nil == ChatSession.get_session("123")
  end

  test "test if session exists" do
    {:ok,_} = ChatSession.assign_session("123")
    id = ChatSession.get_session("123")
    assert is_pid(id)
  end

end

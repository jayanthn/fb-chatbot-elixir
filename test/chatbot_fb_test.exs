defmodule ChatbotFbTest do
  use ExUnit.Case
  doctest ChatbotFb

  test "greets the world" do
    assert ChatbotFb.hello() == :world
  end
end

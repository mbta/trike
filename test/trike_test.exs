defmodule TrikeTest do
  use ExUnit.Case
  doctest Trike

  test "greets the world" do
    assert Trike.hello() == :world
  end
end

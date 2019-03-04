defmodule ExViciTest do
  use ExUnit.Case
  doctest ExVici

  test "greets the world" do
    assert ExVici.hello() == :world
  end
end

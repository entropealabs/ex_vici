defmodule VICIProtocolTest do
  use ExUnit.Case
  doctest VICI

  import VICI.Protocol
  import VICI.Server.Generator

  @atom_map %{
    test: "ok",
    obj: %{
      level2: "test",
      list1: [6, "okok", "ok", "test"],
      level3: %{
        another_list: ["yeah", "ok", "yeah", 6],
        value: 6
      }
    },
    obj2: %{
      yup: ["ok", "okok", 3, 6],
      key: "value",
      key1: 2
    }
  }

  @string_map %{
    "test" => "ok",
    "obj" => %{
      "level2" => "test",
      "list1" => [6, "okok", "ok", "test"],
      "level3" => %{
        "another_list" => ["yeah", "ok", "yeah", 6],
        "value" => 6
      }
    },
    "obj2" => %{
      "yup" => ["ok", "okok", 3, 6],
      "key" => "value",
      "key1" => 2
    }
  }

  test "string map serialize and deserialize" do
    assert deserialize(serialize(@string_map)) == @atom_map
  end

  test "atom map serialize and deserialize" do
    assert deserialize(serialize(@atom_map)) == @atom_map
  end

  test "tuple(Named Event) serialize and deserialize" do
    assert deserialize(serialize(list_sa())) == list_sa()
  end

  test "nil returns empty binary" do
    assert serialize(nil) == <<>>
  end

  test "empty map returns empty binary" do
    assert serialize(%{}) == <<>>
  end
end

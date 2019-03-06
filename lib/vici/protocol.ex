defmodule VICI.Protocol do
  require Logger

  def deserialize(data) do
    deserialize(data, [], %{})
  end

  # SECTION_START
  defp deserialize(
         <<1::integer, key_length::integer, key::binary-size(key_length), rest::binary()>>,
         path,
         result
       ) do
    path = path ++ [String.to_atom(key)]
    deserialize(rest, path, put_in(result, path, %{}))
  end

  # SECTION_END
  defp deserialize(<<2::integer, rest::binary()>>, path, result) do
    path = path |> Enum.reverse() |> tl() |> Enum.reverse()
    deserialize(rest, path, result)
  end

  # KEY_VALUE
  defp deserialize(
         <<3::integer, key_length::integer, key::binary-size(key_length),
           value_length::integer-size(16), value::binary-size(value_length), rest::binary()>>,
         path,
         result
       ) do
    deserialize(rest, path, put_in(result, path ++ [String.to_atom(key)], parse(value)))
  end

  # LIST_START
  defp deserialize(
         <<4::integer, key_length::integer, key::binary-size(key_length), rest::binary()>>,
         path,
         result
       ) do
    path = path ++ [String.to_atom(key)]
    deserialize(rest, path, put_in(result, path, []))
  end

  # LIST_ITEM
  defp deserialize(
         <<5::integer, value_length::integer-size(16), value::binary-size(value_length),
           rest::binary()>>,
         path,
         result
       ) do
    l = get_in(result, path)
    l = l ++ [parse(value)]
    deserialize(rest, path, put_in(result, path, l))
  end

  # SECTION_END
  defp deserialize(<<6::integer, rest::binary()>>, path, result) do
    path = path |> Enum.reverse() |> tl() |> Enum.reverse()
    deserialize(rest, path, result)
  end

  #NAMED EVENT
  defp deserialize(<<n_len::integer, name::binary-size(n_len), data::binary()>>, _, _) do
    {String.to_atom(name), deserialize(data)}
  end

  defp deserialize(<<>>, _path, result), do: result

  def serialize(object) when is_nil(object), do: <<>>

  def serialize(object) when is_map(object) do
    serialize(object, <<>>)
  end

  # Named event
  def serialize(object) when is_tuple(object) do
    name = elem(object, 0) |> Atom.to_string()
    n_len = byte_size(name)
    msg = <<n_len::integer-size(8), name::binary-size(n_len)>>
    serialize(elem(object, 1), msg)
  end

  # TOP LEVEL
  defp serialize(object, msg) when is_map(object) do
    Enum.reduce(object, msg, fn {k, v}, acc ->
      serialize(k, v, acc)
    end)
  end

  # LIST_ITEM
  defp serialize(value, _) when is_binary(value) do
    v_len = byte_size(value)
    <<5::integer-size(8), v_len::integer-size(16), value::binary()>>
  end

  # LIST_ITEM integer
  defp serialize(value, _) when is_integer(value) do
    serialize(Integer.to_string(value), "")
  end

  # Convert atom keys
  defp serialize(key, value, message) when is_atom(key) do
    serialize(Atom.to_string(key), value, message)
  end

  # MAP
  defp serialize(key, value, message) when is_map(value) and is_binary(key) do
    k_len = byte_size(key)
    msg = <<1::integer-size(8), k_len::integer-size(8), key::binary()>>
    message <> serialize(value, msg) <> <<2::integer-size(8)>>
  end

  # KEY_VALUE
  defp serialize(key, value, message) when is_binary(value) and is_binary(key) do
    k_len = byte_size(key)
    v_len = byte_size(value)

    message <>
      <<3::integer-size(8), k_len::integer-size(8), key::binary(), v_len::integer-size(16),
        value::binary()>>
  end

  # KEY_VALUE integer
  defp serialize(key, value, message) when is_integer(value) do
    serialize(key, Integer.to_string(value), message)
  end

  # LIST
  defp serialize(key, value, message) when is_list(value) and is_binary(key) do
    k_len = byte_size(key)
    msg = <<4::integer-size(8), k_len::integer-size(8), key::binary()>>

    msg =
      Enum.reduce(value, msg, fn item, acc ->
        acc <> serialize(item, message)
      end)

    message <> msg <> <<6::integer-size(8)>>
  end

  defp parse(value) when is_binary(value) do
    try do
      String.to_integer(value)
    rescue
      _ -> value
    end
  end
end

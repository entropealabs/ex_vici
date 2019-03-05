defmodule VICI.Connection do
  import VICI.Protocol
  require Logger

  def request(address, port, command, args \\ %{}) do
    {:ok, sock} = connect(address, port)
    send(:request, command, args, sock)
  end

  def request_stream(address, port, {command, event}, args \\ %{}, timeout \\ 1000) do
    {:ok, sock} = connect(address, port)
    Logger.debug("Registering Event: #{event}")
    send(:request_stream, command, event, args, timeout, sock)
  end

  def register(address, port, event, timeout \\ 1000) do
    {:ok, sock} = connect(address, port)
    send(:register, event, timeout, sock)
  end

  defp connect({:local, address}, port) when is_list(address) do
    :gen_tcp.connect({:local, address}, port, [:binary, {:mode, :binary}, {:packet, 4}])
  end

  defp connect({:local, address}, port) when is_binary(address) do
    connect({:local, to_charlist(address)}, port)
  end

  defp connect(address, port) when is_list(address) do
    :gen_tcp.connect(address, port, [:binary, {:mode, :binary}, {:packet, 4}])
  end

  defp connect(address, port) when is_binary(address) do
    connect(to_charlist(address), port)
  end

  defp send(:request_stream, command, event, args, timeout, sock) do
    :ok = do_send(0, command, args, sock)
    :timer.sleep(100)
    :ok = do_send(3, event, %{}, sock)
    loop_stream(sock, timeout)
  end

  defp send(:request, command, args, sock) do
    :ok = do_send(0, command, args, sock)
    loop_request(sock)
  end

  defp send(:register, event, timeout, sock) do
    :ok = do_send(3, event, %{}, sock)
    loop_stream(sock, timeout)
  end

  defp do_send(type, command, args, sock) do
    len = byte_size(command)

    message =
      <<type::integer-size(8), len::integer-size(8), command::binary-size(len)>> <>
        serialize(args)

    :gen_tcp.send(sock, message)
  end

  defp loop_request(sock) do
    receive do
      {:tcp, _port, <<1::integer, data::binary()>>} ->
        Logger.debug("Request Complete")
        :gen_tcp.close(sock)
        {:ok, deserialize(data)}

      o ->
        Logger.debug("Unknown Message: #{inspect(o)}")
        loop_request(sock)
    after
      4_000 ->
        :gen_tcp.close(sock)
        {:error, :timeout}
    end
  end

  defp loop_stream(sock, timeout) do
    receive do
      {:tcp, _port, <<1::integer, _::binary()>>} ->
        Logger.debug("Request Complete")
        loop_stream(sock, timeout)

      {:tcp, _port, <<5::integer>>} ->
        Logger.debug("Event Registered")
        {:ok, create_stream(sock, timeout)}

      {:tcp, _port, <<6::integer>>} ->
        Logger.debug("Unknown Registration")
        {:error, :unknown_event}

      {:tcp, _port, <<7::integer, n_len::integer, name::binary-size(n_len), data::binary()>>} ->
        Logger.debug("Event Message: #{data}")
        {[{String.to_atom(name), deserialize(data)}], {sock, timeout}}

      o ->
        Logger.debug("Unknown Message: #{inspect(o)}")
        loop_stream(sock, timeout)
    after
      timeout ->
        :gen_tcp.close(sock)
        {:halt, {sock, timeout}}
    end
  end

  defp create_stream(sock, timeout) do
    Stream.resource(
      fn -> {sock, timeout} end,
      fn {sock, timeout} -> loop_stream(sock, timeout) end,
      fn {sock, _} -> :gen_tcp.close(sock) end
    )
  end
end

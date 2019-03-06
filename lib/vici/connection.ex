defmodule VICI.Connection do
  import VICI.Protocol
  require Logger

  def request(address, port, command, args \\ %{}) do
    debug("Registering Command: #{command}")
    {:ok, sock} = connect(address, port)
    send(:request, command, args, sock)
  end

  def request_stream(address, port, {command, event}, args \\ %{}, timeout \\ 1000) do
    debug("Registering Event: #{event}")
    debug("Registering Command: #{command}")
    {:ok, sock} = connect(address, port)
    send(:request_stream, command, event, args, timeout, sock)
  end

  def register(address, port, event, timeout \\ 1000) do
    debug("Registering Event: #{event}")
    {:ok, sock} = connect(address, port)
    send(:register, event, timeout, sock)
  end

  defp connect(address, port) when is_list(address) do
    :gen_tcp.connect(address, port, [:binary, {:mode, :binary}, {:packet, 4}])
  end

  defp connect(address, port) when is_binary(address) do
    connect(to_charlist(address), port)
  end

  defp send(:request_stream, command, event, args, timeout, sock) do
    :ok = do_send(3, event, %{}, sock)
    :ok = do_send(0, command, args, sock)
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
        debug("Request Complete")
        :gen_tcp.close(sock)
        {:ok, deserialize(data)}
      {:tcp, _port, <<2::integer>>} ->
        debug("Unknown Command")
        :gen_tcp.close(sock)
        {:error, :unknown_command}
      o ->
        debug("Unknown Message: #{inspect(o)}")
        loop_request(sock)
    after
      500 ->
        :gen_tcp.close(sock)
        {:error, :timeout}
    end
  end

  defp loop_stream(sock, timeout) do
    receive do
      {:tcp, _port, <<5::integer>>} ->
        debug("Event Registered")
        {:ok, create_stream(sock, timeout)}

      {:tcp, _port, <<6::integer>>} ->
        debug("Unknown Registration")
        {:error, :unknown_event}

      {:tcp, _port, <<7::integer, data::binary()>>} ->
        debug("Event Message")
        {[deserialize(data)], {sock, timeout}}

      {:tcp, _port, <<1::integer, _::binary()>>} ->
        debug("Request Complete")
        :gen_tcp.close(sock)
        {:halt, {sock, timeout}}

      o ->
        debug("Unknown Message: #{inspect(o)}")
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

  defp debug(msg) do
    Logger.debug(fn -> msg end)
  end
end

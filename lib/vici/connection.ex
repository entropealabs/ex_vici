defmodule VICI.Connection do
  import VICI.Protocol
  require Logger

  def request(address, port, command, args \\ %{}) do
    {:ok, sock} = connect(address, port)
    send(:request, command, args, sock)
  end

  def request_stream(address, port, command, args \\ %{}, timeout \\ 1000) do
    {:ok, sock} = connect(address, port)
    send(:request_stream, command, args, timeout, sock)
  end

  def register(address, port, event, timeout \\ 1000) do
    {:ok, sock} = connect(address, port)
    send(:register, event, timeout, sock)
  end

  defp connect({:local, address}, port) when is_list(address) do
    :gen_tcp.connect({:local, address}, port, [:binary])
  end

  defp connect({:local, address}, port) when is_binary(address) do
    connect({:local, to_charlist(address)}, port)
  end

  defp connect(address, port) when is_list(address) do
    :gen_tcp.connect(address, port, [:binary])
  end

  defp connect(address, port) when is_binary(address) do
    connect(to_charlist(address), port)
  end

  defp send(:request, command, args, sock) do
    :ok = do_send(0, command, args, sock)
    loop_request(sock)
  end

  defp send(:register, event, timeout, sock) do
    :ok = do_send(3, event, %{}, sock)
    loop_stream(sock, timeout)
  end

  defp send(:request_stream, command, args, timeout, sock) do
    :ok = do_send(0, command, args, sock)
    loop_stream(sock, timeout)
  end

  defp do_send(type, command, args, sock) do
    len = byte_size(command)
    message = <<type::integer-size(8), len::integer-size(8), command::binary-size(len)>>
    packet = <<byte_size(message)::integer-size(32)>> <> message
    :gen_tcp.send(sock, packet)
  end

  defp loop_request(sock) do
    receive do
      {:tcp, _port, <<_l::integer-size(4), 1::integer, data::binary()>>} ->
        :gen_tcp.close(sock)
        {:ok, deserialize(data)}

      _ ->
        loop_request(sock)
    after
      4_000 ->
        :gen_tcp.close(sock)
        {:error, :timeout}
    end
  end

  defp loop_stream(sock, timeout) do
    receive do
      {:tcp, _port, <<_l::integer-size(32), 1::integer>>} = o->
        Logger.info "Message: #{inspect o}"
        {:ok, create_stream(sock, timeout)}

      {:tcp, _port, <<_l::integer-size(32), 5::integer>>} = o ->
        Logger.info "Message: #{inspect o}"
        {:ok, create_stream(sock, timeout)}

      {:tcp, _port, <<_l::integer-size(32), 6::integer>>} = o ->
        Logger.info "Message: #{inspect o}"
        {:error, :unknown_event}

      {:tcp, _port, <<_l::integer-size(32), 7::integer, n_len::integer, name::binary-size(n_len), data::binary()>>} = o->
        Logger.info "Message: #{inspect o}"
        {[{String.to_atom(name), deserialize(data)}], {sock, timeout}}

      o ->
        Logger.info "Message: #{inspect o}"
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

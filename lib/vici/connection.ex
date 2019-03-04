defmodule VICI.Connection do
  import VICI.Protocol

  def request(address, port, command, args \\ %{}) do
    Task.await(
      Task.async(fn ->
        {:ok, sock} = connect(address, port)
        send(:request, command, args, sock)
      end)
    )
  end

  def request_stream(address, port, command, args \\ %{}, timeout \\ 10_000) do
    Task.await(
      Task.async(fn ->
        {:ok, sock} = connect(address, port)
        send(:request_stream, command, args, sock, timeout)
      end)
    )
  end

  def register(address, port, event, args \\ %{}, timeout \\ 10_000) do
    Task.await(
      Task.async(fn ->
        {:ok, sock} = connect(address, port)
        send(:register, event, args, sock, timeout)
      end)
    )
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

  defp send(:request, command, args, sock) do
    :ok = do_send(0, command, args, sock)
    loop_request(sock)
  end

  defp send(:request_stream, command, args, sock, timeout) do
    :ok = do_send(0, command, args, sock)
    loop_stream(sock, timeout)
  end

  defp send(:register, event, args, sock, timeout) do
    :ok = do_send(3, event, args, sock)
    loop_stream(sock, timeout)
  end

  defp do_send(type, command, args, sock) do
    len = String.length(command)
    message = <<type::integer-size(8), len::integer-size(8), command::binary>> <> serialize(args)
    :gen_tcp.send(sock, message)
  end

  defp loop_request(sock) do
    receive do
      {:tcp, _port, <<1::integer, data::binary()>>} ->
        :gen_tcp.close(sock)
        {:ok, deserialize(data)}

      _ ->
        loop_request(sock)
    after
      4_000 ->
        :gen_tcp.close(sock)
    end
  end

  defp loop_stream(sock, timeout) do
    receive do
      {:tcp, _port, <<5::integer>>} ->
        {:ok,
         Stream.resource(
           fn -> {sock, timeout} end,
           fn {sock, timeout} -> loop_stream(sock, timeout) end,
           fn {sock, _} -> :gen_tcp.close(sock) end
         )}

      {:tcp, _port, <<6::integer>>} ->
        {:error, :unknown_registration}

      {:tcp, _port, <<7::integer, data::binary()>>} ->
        {[deserialize(data)], []}

      _ ->
        loop_stream(sock, timeout)
    after
      timeout ->
        :gen_tcp.close(sock)
        {:halt, {sock, timeout}}
    end
  end
end

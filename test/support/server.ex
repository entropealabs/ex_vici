defmodule VICI.Server do
  use GenServer
  require Logger

  import VICI.Protocol
  import VICI.Server.Generator

  def start_link(port) do
    GenServer.start_link(__MODULE__, port)
  end

  def init(port) do
    {:ok, l_sock} = :gen_tcp.listen(port, [:binary, {:mode, :binary}, {:packet, 4}])
    Process.send_after(self(), :accept, 0)
    {:ok, {l_sock, false}}
  end

  defp reply(data, sock) do
    Logger.info "Replying: #{inspect data}"
    Logger.info "Sending to: #{inspect sock}"
    packet = <<1::integer-size(8)>> <> serialize(data)
    :gen_tcp.send(sock, packet)
  end

  defp confirm(data, sock) do
    Logger.info "Confirming"
    Logger.info "Sending to: #{inspect sock}"
    packet = <<5::integer-size(8)>> <> serialize(data)
    :gen_tcp.send(sock, packet)
  end

  defp stream(data, sock) do
    Logger.info "Stream: #{inspect data}"
    packet = <<7::integer-size(8)>> <> serialize(data)
    :gen_tcp.send(sock, packet)
  end

  defp unknown_command(sock) do
    Logger.info "Uknown Command"
    packet = <<2::integer-size(8)>>
    :gen_tcp.send(sock, packet)
  end

  defp unknown_event(sock) do
    Logger.info "Uknown Event"
    packet = <<6::integer-size(8)>>
    :gen_tcp.send(sock, packet)
  end

  def handle_info(:accept, {l_sock, _client}) do
    {:ok, s} = :gen_tcp.accept(l_sock)
    Logger.info "Accepted #{inspect s}"
    {:noreply, {l_sock, false}}
  end

  def handle_info({:tcp, sock, <<0::integer, cmd_len::integer, cmd::binary-size(cmd_len), args::binary()>>}, {l_sock, stream}) do
    Logger.info("Command: #{cmd}")
    Logger.info("Client Socket: #{inspect sock}")
    case handle_command(cmd, sock, deserialize(args)) do
      :unknown_cmd -> unknown_command(sock)
      res ->
        case stream do
          false -> reply(res, sock)
          _ -> :noop
        end
    end
    {:noreply, {l_sock, stream}}
  end

  def handle_info({:tcp, sock, <<3::integer, cmd_len::integer, cmd::binary-size(cmd_len), args::binary()>>}, {l_sock, stream}) do
    Logger.info("Command: #{cmd}")
    Logger.info("Client Socket: #{inspect sock}")
    case handle_event(cmd, sock, deserialize(args)) do
      :unknown_cmd -> unknown_event(sock)
      res -> confirm(res, sock)
    end
    {:noreply, {l_sock, true}}
  end

  def handle_info({:tcp, sock, <<4::integer, cmd_len::integer, cmd::binary-size(cmd_len)>>}, {l_sock, _c}) do
    Logger.info("Unregister: #{cmd}")
    :gen_tcp.close(sock)
    {:noreply, {l_sock, false}}
  end

  def handle_info({:tcp, s, data}, l_sock) do
    Logger.info "Got data: #{inspect data}"
    unknown_command(s)
    {:noreply, l_sock}
  end

  def handle_info({:tcp_closed, s}, {l_sock, _client}) do
    Logger.info "Socket Closed: #{inspect s}"
    Process.send_after(self(), :accept, 0)
    {:noreply, {l_sock, false}}
  end

  def handle_info({:sas, sock}, {_l_sock, true} = state) do
    Enum.each(1..100, fn _i ->
      stream(list_sa(), sock)
      Process.sleep(100)
    end)
    reply(%{}, sock)
    {:noreply, state}
  end

  def handle_info({:sas, _sock}, state), do: {:noreply, state}

  def handle_info({:log, sock}, {_l_sock, true} = state) do
    Enum.each(1..100, fn _i ->
      stream(log(), sock)
      Process.sleep(100)
    end)
    reply(%{}, sock)
    {:noreply, state}
  end

  def handle_info({:log, _sock}, state), do: {:noreply, state}

  defp handle_event(event, sock, args \\ %{})
  defp handle_event("log", sock, _args) do
    Process.send_after(self(), {:log, sock}, 100)
    %{}
  end

  defp handle_event("list-sa", sock, _args) do
    Process.send_after(self(), {:sas, sock}, 100)
    %{}
  end

  defp handle_event(_, _, _), do: :unknown_cmd

  defp handle_command(cmd, sock, args \\ %{})
  defp handle_command("version", _sock, _args) do
    version()
  end

  defp handle_command("stats", _sock, _args) do
    stats()
  end

  defp handle_command("list-sas", _sock, _args) do
    %{}
  end

  defp handle_command(_, _, _), do: :unknown_cmd
end

defmodule VICI.Server do
  use GenServer
  require Logger

  import VICI.Protocol

  def start_link(port) do
    GenServer.start_link(__MODULE__, port)
  end

  def init(port) do
    {:ok, l_sock} = :gen_tcp.listen(port, [:binary, {:mode, :binary}])
    Process.send_after(self(), :accept, 0)
    {:ok, l_sock}
  end

  defp reply(data, sock) do
    Logger.info "Replying: #{inspect data}"
    Logger.info "Sending to: #{inspect sock}"
    packet = <<1::integer-size(8)>> <> serialize(data)
    Logger.info("#{inspect packet}")
    :gen_tcp.send(sock, packet)
  end

  def handle_info(:accept, l_sock) do
    {:ok, s} = :gen_tcp.accept(l_sock)
    Logger.info "Accepted #{inspect s}"
    Process.send_after(self(), :accept, 0)
    {:noreply, l_sock}
  end

  def handle_info({:tcp, sock, <<_len::integer-size(32), 0::integer, cmd_len::integer, cmd::binary-size(cmd_len), args::binary()>>}, l_sock) do
    Logger.info("Command: #{cmd}")
    Logger.info("Socket: #{inspect sock} - #{inspect l_sock}")
    cmd
    |> handle_command(sock, deserialize(args))
    |> reply(sock)
    {:noreply, l_sock}
  end

  def handle_info({:tcp, _s, data}, l_sock) do
    Logger.info "Got data: #{data}"
    {:noreply, l_sock}
  end

  def handle_info({:tcp_closed, _}, l_sock) do
    {:noreply, l_sock}
  end

  def handle_info({:sas, sock}, l_sock) do
    reply(generate_sas(), sock)
    Process.send_after(self(), {:sas, sock}, 100)
    {:noreply, l_sock}
  end

  defp handle_command(cmd, sock, args \\ %{})
  defp handle_command("version", _sock, _args) do
    %{
      daemon: "charon",
      machine: "x86_64",
      release: "4.15.0-45-generic",
      sysname: "Linux",
      version: "5.4.0"
    }
  end

  defp handle_command("stats", _sock, _args) do
    %{
      ikesas: %{"half-open": 0, total: 0},
      plugins: ["charon", "random", "nonce", "x509", "revocation", "constraints",
        "pubkey", "pkcs1", "pkcs7", "pkcs8", "pkcs12", "pgp", "dnskey", "sshkey",
        "pem", "openssl", "fips-prf", "gmp", "xcbc", "cmac", "curl", "sqlite",
        "attr", "kernel-netlink", "resolve", "socket-default", "farp", "stroke",
        "vici", "updown", "eap-identity", "eap-sim", "eap-aka", "eap-aka-3gpp2",
        "eap-simaka-pseudonym", "eap-simaka-reauth", "eap-md5", "eap-mschapv2",
        "eap-radius", "eap-tls", "xauth-generic", "xauth-eap", "dhcp", "unity"
      ],
      queues: %{critical: 0, high: 0, low: 0, medium: 0}, scheduled: 0,
      uptime: %{running: "2 hours", since: "Mar 03 19:14:47 2019"},
      workers: %{active: %{critical: 4, high: 0, low: 0, medium: 1}, idle: 11,
      total: 16}
    }
  end

  defp handle_command("list-sas", sock, _args) do
    Process.send_after(self(), {:sas, sock}, 100)
    generate_sas()
  end

  defp generate_sas() do
    %{
      id: :rand.uniform(99999),
      bytes_in: :rand.uniform(9999999999999),
      bytes_out: :rand.uniform(9999999999999),
      packets_in: :rand.uniform(9999999999999),
      packets_out: :rand.uniform(9999999999999)
    }
  end
end

defmodule VICI do
  @moduledoc """
  See [VICI-PROTOCOL](../VICI-PROTOCOL.md) for full details on arguments and return values
  """

  alias VICI.Connection, as: Conn

  @events %{
    log: "log",
    control_log: "control-log",
    list_sa: "list-sa",
    list_policy: "list-policy",
    list_conn: "list-conn",
    list_cert: "list-cert",
    list_authority: "list-authority",
    ike_updown: "ike-updown",
    ike_rekey: "ike-rekey",
    child_updown: "child-updown",
    child_rekey: "child-rekey"
  }

  def register(key, timeout, address, port) do
    Conn.register(address, port, Map.get(@events, key), timeout)
  end

  def version(address, port) do
    Conn.request(address, port, "version")
  end

  def stats(address, port) do
    Conn.request(address, port, "stats")
  end

  def reload_settings(address, port) do
    Conn.request(address, port, "reload-settings")
  end

  def initiate(address, port, args \\ %{}, timeout \\ 5_000) do
    Conn.request_stream(address, port, "initiate", args, timeout)
  end

  def terminate(address, port, args \\ %{}, timeout \\ 5_000) do
    Conn.request_stream(address, port, "terminate", args, timeout)
  end

  def rekey(address, port, args \\ %{}) do
    Conn.request(address, port, "rekey", args)
  end

  def redirect(address, port, args \\ %{}) do
    Conn.request(address, port, "redirect", args)
  end

  def install(address, port, args \\ %{}) do
    Conn.request(address, port, "install", args)
  end

  def uninstall(address, port, args \\ %{}) do
    Conn.request(address, port, "uninstall", args)
  end

  def list_sas(address, port, args \\ %{}, timeout \\ 5_000) do
    Conn.request_stream(address, port, "list-sas", args, timeout)
  end

  def list_policies(address, port, args \\ %{}, timeout \\ 5_000) do
    Conn.request_stream(address, port, "list-policies", args, timeout)
  end

  def list_conns(address, port, args \\ %{}, timeout \\ 5_000) do
    Conn.request_stream(address, port, "list-conns", args, timeout)
  end

  def get_conns(address, port) do
    Conn.request(address, port, "get-conns")
  end

  def list_certs(address, port, args \\ %{}, timeout \\ 5_000) do
    Conn.request_stream(address, port, "list-certs", args, timeout)
  end

  def list_authorities(address, port, args \\ %{}, timeout \\ 5_000) do
    Conn.request_stream(address, port, "list-authorities", args, timeout)
  end

  def get_authorities(address, port) do
    Conn.request(address, port, "get-authorities")
  end

  def load_conn(address, port, args \\ %{}) do
    Conn.request(address, port, "load-conn", args)
  end

  def unload_conn(address, port, args \\ %{}) do
    Conn.request(address, port, "unload-conn", args)
  end

  def load_cert(address, port, args \\ %{}) do
    Conn.request(address, port, "load-cert", args)
  end

  def load_key(address, port, args \\ %{}) do
    Conn.request(address, port, "load-key", args)
  end

  def unload_key(address, port, args \\ %{}) do
    Conn.request(address, port, "unload-key", args)
  end

  def get_keys(address, port) do
    Conn.request(address, port, "get-keys")
  end

  def load_token(address, port, args \\ %{}) do
    Conn.request(address, port, "load-token", args)
  end

  def load_shared(address, port, args \\ %{}) do
    Conn.request(address, port, "load-shared", args)
  end

  def unload_shared(address, port, args \\ %{}) do
    Conn.request(address, port, "unload-shared", args)
  end

  def get_shared(address, port) do
    Conn.request(address, port, "get-shared")
  end

  def flush_certs(address, port, args \\ %{}) do
    Conn.request(address, port, "flush-certs", args)
  end

  def clear_creds(address, port) do
    Conn.request(address, port, "clear-creds")
  end

  def load_authority(address, port, args \\ %{}) do
    Conn.request(address, port, "load-authority", args)
  end

  def unload_authority(address, port, args \\ %{}) do
    Conn.request(address, port, "unload-authority", args)
  end

  def load_pool(address, port, args \\ %{}) do
    Conn.request(address, port, "load-pool", args)
  end

  def unload_pool(address, port, args \\ %{}) do
    Conn.request(address, port, "unload-pool", args)
  end

  def get_pools(address, port, args \\ %{}) do
    Conn.request(address, port, "get-pools", args)
  end

  def get_algorithms(address, port) do
    Conn.request(address, port, "get-algorithms")
  end

  def get_counters(address, port, args \\ %{}) do
    Conn.request(address, port, "get-counters", args)
  end

  def reset_counters(address, port, args \\ %{}) do
    Conn.request(address, port, "reset-counters", args)
  end

end

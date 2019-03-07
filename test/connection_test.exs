defmodule VICIConnectionTest do
  use ExUnit.Case, async: true
  doctest VICI

  alias VICI.{Connection, Server}
  import Server.Generator

  setup _ctx do
    port = 5001
    {:ok, _pid} = Server.start_link(port)
    [
      host: "localhost",
      port: port
    ]
  end

  test "version request", ctx do
    assert VICI.version(ctx.host, ctx.port) == {:ok, version()}
  end

  test "stats request", ctx do
    assert VICI.stats(ctx.host, ctx.port) == {:ok, stats()}
  end

  test "event registration", ctx do
    {:ok, logs} = VICI.register(:log, 1000, ctx.host, ctx.port)
    [head | _] = Enum.map(logs, fn l -> l end)
    assert head == log()
  end

  test "stream request", ctx do
    {:ok, sas} = VICI.list_sas(ctx.host, ctx.port, %{}, 1000)
    [head | _] = Enum.map(sas, fn l -> l end)
    assert head == list_sa()
  end

  test "unknown registration", ctx do
    assert Connection.register(ctx.host, ctx.port, "unknown", 1000) == {:error, :unknown_event}
  end

  test "unknown command", ctx do
    assert Connection.request(ctx.host, ctx.port, "unknown", %{}) == {:error, :unknown_command}
  end

  test "registration timeout returns empty list", ctx do
    {:ok, conns} = VICI.register(:list_conn, 100, ctx.host, ctx.port)
    assert Enum.map(conns, fn l -> l end) == []
  end

  test "request timeout returns error", ctx do
    assert VICI.get_conns(ctx.host, ctx.port) == {:error, :timeout}
  end

  test "unknown response timeout", ctx do
    assert VICI.reload_settings(ctx.host, ctx.port) == {:error, :timeout}
  end

  test "unknown response from registration timeout", ctx do
    {:ok, conns} = VICI.register(:list_cert, 100, ctx.host, ctx.port)
    assert Enum.map(conns, fn l -> l end) == []
  end
end

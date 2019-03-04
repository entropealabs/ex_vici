# VICI

The Versatile IKE Control Interface (VICI) protocol is used by [strongSwan](https://strongswan.org/) for controlling and monitoring the Charon daemon.

It's a simple binary protocol interfaced over a socket, TCP or local/UNIX.

This library provides a full serialization and deserialization implementation and relies on the [VICI protocol documents](./VICI-PROTOCOL.md) for full documentation of the different arguments and return values.

There is full support for the streaming interface by registering for events or making a request that returns a stream eg; log, list-sas, etc.

This VICI library doesn't provide any connection pooling or anything, each request is a new gen_tcp connection that is automatically cleaned up after each request.

Any request or registration that supports the `:timeout` option accepts `:infinity` as an option to keep the connection open forever, but remember this will block forever if you don't close the Stream.resource that is returned.

Local UNIX sockets should work fine, but there has been limited testing done.

## Example usage

Ensure you have a StrongSwan server running locally with the VICI plugin opening a socket at `tcp://127.0.0.1:5000`

[Docs](https://wiki.strongswan.org/projects/strongswan/wiki/Vici)

### VICI configuration

`./strongswan.d/charon/vici.conf`

```
vici {

    # Whether to load the plugin. Can also be an integer to increase the
    # priority of this plugin.
    load = yes

    # Socket the vici plugin serves clients.
    socket = tcp://127.0.0.1:5000

}
```

### IEX Session

```elixir
$ iex -S mix
Erlang/OTP 20 [erts-9.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (1.5.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> VICI.version("localhost", 5000)
{:ok,
  %{daemon: "charon", machine: "x86_64", release: "4.15.0-45-generic",
    sysname: "Linux", version: "5.4.0"}}
iex(2)> VICI.stats("localhost", 5000)  
{:ok,
  %{ikesas: %{"half-open": 0, total: 0},
    plugins: ["charon", "random", "nonce", "x509", "revocation", "constraints",
    "pubkey", "pkcs1", "pkcs7", "pkcs8", "pkcs12", "pgp", "dnskey", "sshkey",
    "pem", "openssl", "fips-prf", "gmp", "xcbc", "cmac", "curl", "sqlite",
    "attr", "kernel-netlink", "resolve", "socket-default", "farp", "stroke",
    "vici", "updown", "eap-identity", "eap-sim", "eap-aka", "eap-aka-3gpp2",
    "eap-simaka-pseudonym", "eap-simaka-reauth", "eap-md5", "eap-mschapv2",
    "eap-radius", "eap-tls", "xauth-generic", "xauth-eap", "dhcp", "unity"],
    queues: %{critical: 0, high: 0, low: 0, medium: 0}, scheduled: 0,
    uptime: %{running: "68 minutes", since: "Mar 03 18:40:28 2019"},
    workers: %{active: %{critical: 4, high: 0, low: 0, medium: 1}, idle: 11,
     total: 16}
    }
  }
iex(3)> VICI.register(:log, 5_000, 'localhost', 5000)
{:ok, #Function<50.51599720/2 in Stream.resource/3>}
iex(4)> {:ok, logs} = VICI.register(:log, 5_000, "localhost", 5000)
{:ok, #Function<50.51599720/2 in Stream.resource/3>}
iex(5)> Enum.each(logs, fn log -> IO.puts(log) end)                
:ok
iex(6)> {:ok, sas} = VICI.list_sas("localhost", 5000)              
{:ok, #Function<50.51599720/2 in Stream.resource/3>}
iex(7)> Enum.each(sas, fn sa -> IO.puts(sa) end)     
:ok
iex(8)>
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `monitor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_vici, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/monitor](https://hexdocs.pm/monitor).

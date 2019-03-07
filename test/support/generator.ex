defmodule VICI.Server.Generator do
  def version do
    %{
      daemon: "charon",
      machine: "x86_64",
      release: "4.15.0-45-generic",
      sysname: "Linux",
      version: "5.4.0"
    }
  end

  def child_updown do
    {:"child-updown",
     %{
       up: "true",
       test_sa: list_sa() |> elem(1) |> get_in([:"cluster-eks-research", :"child-sas"])
     }}
  end

  def stats do
    %{
      ikesas: %{"half-open": 0, total: 0},
      plugins: [
        "charon",
        "random",
        "nonce",
        "x509",
        "revocation",
        "constraints",
        "pubkey",
        "pkcs1",
        "pkcs7",
        "pkcs8",
        "pkcs12",
        "pgp",
        "dnskey",
        "sshkey",
        "pem",
        "openssl",
        "fips-prf",
        "gmp",
        "xcbc",
        "cmac",
        "curl",
        "sqlite",
        "attr",
        "kernel-netlink",
        "resolve",
        "socket-default",
        "farp",
        "stroke",
        "vici",
        "updown",
        "eap-identity",
        "eap-sim",
        "eap-aka",
        "eap-aka-3gpp2",
        "eap-simaka-pseudonym",
        "eap-simaka-reauth",
        "eap-md5",
        "eap-mschapv2",
        "eap-radius",
        "eap-tls",
        "xauth-generic",
        "xauth-eap",
        "dhcp",
        "unity"
      ],
      queues: %{critical: 0, high: 0, low: 0, medium: 0},
      scheduled: 0,
      uptime: %{running: "2 hours", since: "Mar 03 19:14:47 2019"},
      workers: %{active: %{critical: 4, high: 0, low: 0, medium: 1}, idle: 11, total: 16}
    }
  end

  def log do
    {:log,
     %{
       group: "ike",
       level: 2,
       thread: 4,
       "ikesa-name": "kiosk-10-a",
       "ikesa-uniqued": "sd876876",
       msg: "this is a log message"
     }}
  end

  def list_sa do
    {:"list-sa",
     %{
       "cluster-eks-research": %{
         "child-sas": %{
           "cluster-eks-research-1078": %{
             "bytes-in": 872364,
             "bytes-out": 28937492874,
             "dh-group": "MODP_3072",
             encap: "yes",
             "encr-alg": "AES_CBC",
             "encr-keysize": 128,
             "install-time": 3468,
             "integ-alg": "HMAC_SHA2_256_128",
             "life-time": 132,
             "local-ts": ["0.0.0.0/0"],
             mode: "TUNNEL",
             name: "cluster-eks-research",
             "packets-in": 203948029384,
             "packets-out": 298374,
             protocol: "ESP",
             "rekey-time": -761,
             "remote-ts": ["10.25.0.0/16"],
             reqid: 12,
             "spi-in": "cec120c2",
             "spi-out": "692ac1ba",
             state: "REKEYED",
             uniqueid: 1078
           },
           "cluster-eks-research-1338": %{
             "bytes-in": 99999,
             "bytes-out": 209384029384,
             "dh-group": "MODP_3072",
             encap: "yes",
             "encr-alg": "AES_CBC",
             "encr-keysize": 128,
             "install-time": 761,
             "integ-alg": "HMAC_SHA2_256_128",
             "life-time": 2839,
             "local-ts": ["0.0.0.0/0"],
             mode: "TUNNEL",
             name: "cluster-eks-research",
             "packets-in": 298374,
             "packets-out": 29384,
             protocol: "ESP",
             "rekey-time": 1886,
             "remote-ts": ["10.25.0.0/16"],
             reqid: 12,
             "spi-in": "ce8240fa",
             "spi-out": "a7c05cf7",
             state: "INSTALLED",
             uniqueid: 1338
           }
         },
         "dh-group": "MODP_3072",
         "encr-alg": "AES_CBC",
         "encr-keysize": 128,
         established: 14171,
         initiator: "yes",
         "initiator-spi": "0f8bf7f4b77e071f",
         "integ-alg": "HMAC_SHA2_256_128",
         "local-host": "192.168.255.39",
         "local-id": "kiosk-gw.citybase.thecb.net",
         "local-port": 4500,
         "nat-any": "yes",
         "nat-local": "yes",
         "nat-remote": "yes",
         "prf-alg": "PRF_HMAC_SHA2_256",
         "rekey-time": 71545,
         "remote-host": "34.214.198.129",
         "remote-id": "34.214.198.129",
         "remote-port": 4500,
         "responder-spi": "6768c8c1f1599462",
         state: "ESTABLISHED",
         uniqueid: 3,
         version: 1
       }
     }}
  end
end

defmodule VICI.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_vici,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
    ]
  end

  def elixirc_paths(_) do
    ["lib", "test/support"]
  end

  defp deps do
    []
  end
end

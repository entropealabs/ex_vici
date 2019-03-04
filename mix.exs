defmodule VICI.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_vici
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [],
    ]
  end

  defp deps do
    []
  end
end

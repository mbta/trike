defmodule Trike.MixProject do
  use Mix.Project

  def project do
    [
      app: :trike,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Trike.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ranch, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:tzdata, "~> 1.1"}
    ]
  end
end

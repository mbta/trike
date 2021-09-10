defmodule Trike.MixProject do
  use Mix.Project

  def project do
    [
      app: :trike,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: LcovEx, output: "cover"],
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Trike.Application, []}
    ]
  end

  defp aliases do
    [
      check: ["format --check-formatted", "credo", "dialyzer"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ranch, "~> 2.0"},
      {:ehmon, git: "https://github.com/mbta/ehmon.git"},
      {:logger_splunk_backend, "~> 2.0.0"},
      {:jason, "~> 1.2"},
      {:tzdata, "~> 1.1"},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_kinesis, "~> 2.0"},
      {:hackney, "~> 1.17"},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:lcov_ex, "~> 0.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end
end

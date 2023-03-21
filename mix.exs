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
      {:ranch, "~> 2.1"},
      {:ehmon, git: "https://github.com/mbta/ehmon.git"},
      {:jason, "~> 1.4"},
      {:tzdata, "~> 1.1"},
      {:ex_aws, "~> 2.4"},
      {:ex_aws_kinesis, "~> 2.0"},
      {:configparser_ex, "~> 4.0", only: [:prod]},
      {:req, "~> 0.3.6"},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:lcov_ex, "~> 0.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:sentry, "~> 8.0"}
    ]
  end
end

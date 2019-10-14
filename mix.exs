defmodule Elastix.Mixfile do
  use Mix.Project

  @version "0.7.1"

  def project do
    [
      app: :elastix,
      version: @version,
      elixir: "~> 1.0",
      description: "A DSL-free Elastic / Elasticsearch client for Elixir.",
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      name: "Elastix",
      docs: docs()
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :httpoison, :retry]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev},
      {:credo, "~> 0.6", only: [:dev, :test]},
      {:mix_test_watch, "~> 0.3", only: [:test, :dev]},
      {:poison, "~> 4.0", optional: true},
      {:httpoison, "~> 1.4"},
      {:retry, "~> 0.8"}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["El Werbitzky", "evuez <helloevuez@gmail.com>"],
      licenses: ["WTFPL 2"],
      links: %{"GitHub" => "https://github.com/werbitzky/elastix"}
    ]
  end

  defp aliases do
    [compile: ["compile --warnings-as-errors"]]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "pages/custom-json-codec.md"]
    ]
  end
end

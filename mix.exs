defmodule Elastix.Mixfile do
  use Mix.Project

  @source_url "https://github.com/werbitzky/elastix"
  @version "0.10.0"

  def project do
    [
      app: :elastix,
      name: "Elastix",
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :httpoison]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:jason, "~> 1.4", optional: true},
      {:httpoison, "~> 2.2"},
      {:retry, "~> 0.8", only: [:dev, :test]},
      {:styler, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      description: "A DSL-free Elastic / Elasticsearch client for Elixir.",
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md", "LICENSE"],
      maintainers: ["El Werbitzky", "evuez <helloevuez@gmail.com>", "Fabian Becker"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/elastix/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp aliases do
    [compile: ["compile --warnings-as-errors"]]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md",
        {:LICENSE, [title: "License"]},
        "README.md",
        "pages/custom-json-codec.md"
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end

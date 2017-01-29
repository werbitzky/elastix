defmodule Elastix.Mixfile do
  use Mix.Project

  @version "0.3.0"

  def project do
    [app: :elastix,
     version: @version,
     elixir: "~> 1.0",
     description: "A simple Elasticsearch REST client written in Elixir.",
     package: package(),
     docs: [source_ref: "v#{@version}", main: "overview"],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :httpoison]]
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
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.7", only: :dev},
     {:credo, "~> 0.5", only: [:dev, :test]},
     {:mix_test_watch, "~> 0.2", only: [:test, :dev]},
     {:poison, "~> 1.5 or ~> 2.0"},
     {:httpoison, "~> 0.10"}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md"],
      maintainers: ["El Werbitzky"],
      licenses: ["WTFPL 2"],
      links: %{"GitHub" => "https://github.com/werbitzky/elastix"}]
  end
end

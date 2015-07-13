defmodule Elastix.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :elastix,
     version: @version,
     elixir: "~> 1.0",
     contributors: ["El Werbitzky"],
     description: "Simple Elastic Client",
     source_url: "https://github.com/werbitzky/elastix",
     homepage_url: "https://github.com/werbitzky/elastix",
     docs: [source_ref: "v#{@version}", main: "overview"],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :httpotion]]
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
     {:poison, "~> 1.4"},
     {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.1"},
     {:httpotion, "~> 2.1.0"}]
  end
end

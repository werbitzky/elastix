use Mix.Config

config :elastix, Elastix,
  elastic_url: System.get_env("ELASTIC_URL")

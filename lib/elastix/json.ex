defmodule Elastix.JSON do
  @moduledoc """
  A wrapper for JSON libraries with Poison as the default implementation.

  To override, implement the `Elastix.JSON.Codec` behavior and specify it in the config:

  ```
  config :elastix,
    json_codec: JiffyCodec
  ```

  Decode options can be specified in the config:

  ```
  # Poison decode with atom keys
  config :elastix,
    json_options: [keys: atoms!]
  ```

  ```
  # Jiffy decode with maps
  config :elastix,
    json_codec: JiffyCodec,
    json_options: [:return_maps]
  ```
  """

  defmodule Codec do
    @moduledoc """
    A behaviour for JSON serialization.
    """

    @callback encode!(data :: any) :: iodata

    @callback decode(json :: iodata, opts :: []) :: {:ok, any} | {:error, :invalid}
  end

  @doc false
  def encode!(data) do
    codec().encode!(data)
  end

  @doc false
  def decode(json) do
    codec().decode(json, json_options())
  end

  @doc false
  defp json_options do
    Elastix.config(:json_options, [])
  end

  defp codec do
    Elastix.config(:json_codec, Jason)
  end
end

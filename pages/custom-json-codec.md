# Custom JSON codec

To use a different JSON library you must pass in the `json_codec` option:

```elixir
config :elastix,
  json_codec: JiffyCodec,
  json_options: [:return_maps]
```

This must be a module that implements the [`Elastix.JSON.Codec`](lib/elastix/json.ex) behavior:

```elixir
defmodule JiffyCodec do
  @behaviour Elastix.JSON.Codec

  def encode!(data), do: :jiffy.encode(data)
  def decode(json, opts \\ []), do: {:ok, :jiffy.decode(json, opts)}
end
```

Or you can just a library that already provides this interface, like [Jason](https://github.com/michalmuskala/jason):

```elixir
config :elastix,
  json_codec: Jason
```

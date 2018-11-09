# Elastix [![Hex Version](https://img.shields.io/hexpm/v/elastix.svg)](https://hex.pm/packages/elastix) [![Hex Downloads](https://img.shields.io/hexpm/dt/elastix.svg)](https://hex.pm/packages/elastix) [![Build Status](https://travis-ci.org/werbitzky/elastix.svg)](https://travis-ci.org/werbitzky/elastix) [![WTFPL](https://img.shields.io/badge/license-WTFPL-brightgreen.svg?style=flat)](https://www.tldrlegal.com/l/wtfpl)

A DSL-free Elasticsearch client for Elixir.

## Documentation

* [Documentation on hexdocs.pm](https://hexdocs.pm/elastix/)
* [Latest Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

Even though the [documentation](https://hexdocs.pm/elastix/) is pretty scarce right now, we're working on improving it. If you want to help with that you're definitely welcome 🤗

This README contains most of the information you should need to get started, if you can't find what you're looking for, either look at the tests or file an issue!

## Installation

Add `elastix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:elastix, ">= 0.0.0"}]
end
```

Then run `mix deps.get` to fetch the new dependency.

## Examples

### Creating an Elasticsearch index

```elixir
Elastix.Index.create("http://localhost:9200", "twitter", %{})
```

### Map, Index, Search and Delete

```elixir
elastic_url = "http://localhost:9200"

data = %{
    user: "kimchy",
    post_date: "2009-11-15T14:12:12",
    message: "trying out Elastix"
}

mapping = %{
  properties: %{
    user: %{type: "text"},
    post_date: %{type: "date"},
    message: %{type: "text"}
  }
}

Elastix.Mapping.put(elastic_url, "twitter", "tweet", mapping)
Elastix.Document.index(elastic_url, "twitter", "tweet", "42", data)
Elastix.Search.search(elastic_url, "twitter", ["tweet"], %{})
Elastix.Document.delete(elastic_url, "twitter", "tweet", "42")
```

### Bulk requests

Bulk requests take as parameter a list of the lines you want to send to the [`_bulk`](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html) endpoint.

You can also specify the following options:

* `index` the index of the request
* `type` the document type of the request. *(you can't specify `type` without specifying `index`)*
* `httpoison_options` configuration directly passed to httpoison methods. Same options that can be passed on config file

```elixir
lines = [
  %{index: %{_id: "1"}},
  %{field: "value1"},
  %{index: %{_id: "2"}},
  %{field: "value2"}
]

Elastix.Bulk.post(elastic_url, lines, index: "my_index", type: "my_type", httpoison_options: [timeout: 180_000])

# You can also send raw data:
data = Enum.map(lines, fn line -> Poison.encode!(line) <> "\n" end)
Elastix.Bulk.post_raw(elastic_url, data, index: "my_index", type: "my_type")
```

## Configuration

### [Shield](https://www.elastic.co/products/shield)

```elixir
config :elastix,
  shield: true,
  username: "username",
  password: "password",
```

### [Poison](https://github.com/devinus/poison) (or any other JSON library) and [HTTPoison](https://github.com/edgurgel/httpoison)

```elixir
config :elastix,
  json_options: [keys: :atoms!],
  httpoison_options: [hackney: [pool: :elastix_pool]]
```

Note that you can configure Elastix to use any JSON library, see the ["Custom JSON codec" page](https://hexdocs.pm/elastix/custom-json-codec.html) for more info.

### Custom headers

```elixir
config :elastix,
  custom_headers: {MyModule, :add_aws_signature, ["us-east"]}
```

`custom_headers` must be a tuple of the type `{Module, :function, [args]}`, where `:function` is a function that should accept the request (a map of this type: `%{method: String.t, headers: [], url: String.t, body: String.t}`) as its first parameter and return a list of the headers you want to send:

```elixir
defmodule MyModule do
  def add_aws_signature(request, region) do
    [{"Authorization", generate_aws_signature(request, region)} | request.headers]
  end

  defp generate_aws_signature(request, region) do
    # See: https://github.com/bryanjos/aws_auth or similar
  end
end
```

## Running tests

You need Elasticsearch running locally on port 9200. A quick way of doing so is via Docker:

```
$ docker run -p 9200:9200 -it --rm elasticsearch:5.1.2
```

Then clone the repo and fetch its dependencies:

```
$ git clone git@github.com:werbitzky/elastix.git
$ cd elastix
$ mix deps.get
$ mix test
```

## License

Copyright © 2017 El Werbitzky werbitzky@gmail.com

This work is free. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

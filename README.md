# Elastix [![Hex Version](https://img.shields.io/hexpm/v/elastix.svg)](https://hex.pm/packages/elastix) [![Hex Downloads](https://img.shields.io/hexpm/dt/elastix.svg)](https://hex.pm/packages/elastix) [![Build Status](https://travis-ci.org/werbitzky/elastix.svg)](https://travis-ci.org/werbitzky/elastix) [![WTFPL](https://img.shields.io/badge/license-WTFPL-brightgreen.svg?style=flat)](https://www.tldrlegal.com/l/wtfpl)

A simple Elastic REST client written in Elixir.

## Preface

* [Official Elastic Website](https://www.elastic.co)
* [and latest docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

This library talks to the Elastic(search) server through the HTTP/REST/JSON API. Its methods almost always return a [HTTPoison](https://github.com/edgurgel/httpoison) request object.

When needed, the payload can be provided as an Elixir Map, which is internally converted to JSON. The library does not assume anything else regarding the payload and also does not (and will never) provide a magic DSL to generate the payload. That way users can directly manipulate the API data, that is sent to the Elastic server.

## Overview

Elastix has *5 main modules* and one *utility module*, that can be used, if the call/feature you want is not implemented (yet). However – please open issues or provide pull requests so I can improve the software for everybody. The modules are:

* [Elastix.Index](lib/elastix/index.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html)
* [Elastix.Document](lib/elastix/document.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html)
* [Elastix.Search](lib/elastix/search.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html)
* [Elastix.Bulk](lib/elastix/bulk.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html)
* [Elastix.Mapping](lib/elastix/mapping.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)
* and [Elastix.HTTP](lib/elastix/http.ex) – a thin [HTTPoison](https://github.com/edgurgel/httpoison) wrapper

I will try and provide documentation and examples for all of them with time, for now just consult the source code.

## Simple Example

start elastix application dependencies (or define it as an application dependency in ```mix.exs```):

```elixir
Elastix.start()

```

create the Elastic index

```elixir
Elastix.Index.create("http://127.0.0.1:9200", "sample_index_name", %{})

```

assuming you have a model ```product``` create a document, search, or delete

```elixir

# Elastic Server URL
elastic_url = "http://127.0.0.1:9200"

# Elastic Index Name
index_name = "shop_api_production"

# Elastic Document Type
doc_type = "product"

index_data = %{
  name: product.name,
  item_number: product.item_number,
  inserted_at: product.inserted_at,
  updated_at: product.updated_at
}

# Add mapping
mapping = %{
  properties: %{
    name: %{type: "text"},
    item_number: %{type: "integer"},
    inserted_at: %{type: "date"},
    updated_at: %{type: "date"}
  }
}

# add some search params according to Elastic JSON API
search_payload = %{}

# which document types should be included in the search?
search_in = [doc_type]

Elastix.Mapping.put(elastic_url, index_name, doc_type, mapping)
Elastix.Document.index(elastic_url, index_name, doc_type, product.id, index_data)
Elastix.Search.search(elastic_url, index_name, search_in, search_payload)
Elastix.Document.delete(elastic_url, index_name, doc_type, product.id)

```

### Bulk request

It is possible to execute `bulk` requests with *elastix*.

Bulk requests take as parameters the list of lines to send to *Elasticsearch*. You can also optionally give them options. Available options are:

* `index` the index of the request
* `type` the document type of the request. *(you can't specify `type` without specifying `index`)*

**Examples**

```elixir
lines = [
  %{index: %{_id: "1"}},
  %{field: "value1"},
  %{index: %{_id: "2"}},
  %{field: "value2"}
]

# Send bulk data
Elastix.Bulk.post elastic_url, lines, index: "my_index", type: "my_type"
# Send your lines by transforming them to iolist
Elastix.Bulk.post_to_iolist elastic_url, lines, index: "my_index", type: "my_type"

# Send raw data directly to the API
data = Enum.map(lines, fn line -> Poison.encode!(line) <> "\n" end)

Elastix.Bulk.post_raw elastic_url, data, index: "my_index", type: "my_type"

# Finally, you can specify the index or the type directly in you lines
lines = [
  %{index: %{_id: "1", _index: "my_index", _type: "my_type"}},
  %{field: "value1"},
  %{index: %{_id: "2", _index: "my_other_index", _type: "my_other_type"}},
  %{field: "value2"}
]

Elastix.Bulk.post elastic_url, lines
```

## Configuration

Currently we can
  * pass options to the JSON decoder used by Elastix ([poison](https://github.com/devinus/poison))
  * optionally use shield for authentication ([shield](https://www.elastic.co/products/shield))
  * optionally pass along custom headers for every request made to the elasticsearch server(s)s

by setting the respective keys in your `config/config.exs`

```elixir
config :elastix,
  poison_options: [keys: :atoms],
  shield: true,
  username: "username",
  password: "password"
```

The above for example will
  * lead to the HTTPoison responses being parsed into maps with atom keys instead of string keys (be careful as most of the time this is not a good idea as stated here: https://github.com/devinus/poison#parser).
  * use shield for authentication

## License

Copyright © 2017 El Werbitzky <werbitzky@gmail.com>
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See [http://www.wtfpl.net/](http://www.wtfpl.net/) for more details.

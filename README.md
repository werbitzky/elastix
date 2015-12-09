# Elastix [![Hex Version](https://img.shields.io/hexpm/v/elastix.svg)](https://hex.pm/packages/elastix) [![Hex Downloads](https://img.shields.io/hexpm/dt/elastix.svg)](https://hex.pm/packages/elastix) [![Build Status](https://travis-ci.org/werbitzky/elastix.svg)](https://travis-ci.org/werbitzky/elastix) [![WTFPL](https://img.shields.io/badge/license-WTFPL-brightgreen.svg?style=flat)](https://www.tldrlegal.com/l/wtfpl)

A simple Elastic REST client written in Elixir.

## Preface

* [Official Elastic Website](https://www.elastic.co)
* [and latest docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

This library talks to the Elastic(search) server through the HTTP/REST/JSON API. Its methods almost always return a [HTTPoison](https://github.com/edgurgel/httpoison) request object.

When needed, the payload can be provided as an Elixir Map, which is internally converted to JSON. The library does not assume anything else regarding the payload and also does not (and will never) provide a magic DSL to generate the payload. That way users can directly manipulate the API data, that is sent to the Elastic server.

## Overview

Elastix has *3 main modules* and one *utility module*, that can be used, if the call/feature you want is not implemented (yet). However – please open issues or provide pull requests so I can improve the software for everybody. The modules are:

* [Elastix.Index](lib/elastix/index.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html)
* [Elastix.Document](lib/elastix/document.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html)
* [Elastix.Search](lib/elastix/search.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html)
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

index_data = %{
  name: product.name,
  item_number: product.item_number,
  inserted_at: product.inserted_at,
  updated_at: product.updated_at
}

# add some search params according to Elastic JSON API
search_payload = %{}

Elastix.Document.index(elastic_url, "sample_index_name", "product", product.id, index_data)
Elastix.Search.search(elastic_url, "sample_index_name", ["product"], search_payload)
Elastix.Document.delete(elastic_url, "sample_index_name", "product", product.id)

```

## License

Copyright © 2015 El Werbitzky <werbitzky@gmail.com>
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See [http://www.wtfpl.net/](http://www.wtfpl.net/) for more details.

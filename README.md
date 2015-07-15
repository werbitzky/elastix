# Elastix [![Hex Version](https://img.shields.io/hexpm/v/elastix.svg)](https://hex.pm/packages/elastix) [![Hex Downloads](https://img.shields.io/hexpm/dt/elastix.svg)](https://hex.pm/packages/elastix) [![Build Status](https://travis-ci.org/werbitzky/elastix.svg)](https://travis-ci.org/werbitzky/elastix) [![WTFPL](https://img.shields.io/badge/license-WTFPL-brightgreen.svg?style=flat)](https://www.tldrlegal.com/l/wtfpl)

A simple Elastic REST client written in Elixir.

## Preface

* [Official Elastic Website](https://www.elastic.co)
* [and latest docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

This library talks to the Elastic(search) server through the HTTP/REST/JSON API. Its methods almost always return a [HTTPotion](https://github.com/myfreeweb/httpotion) request object.

When needed, the payload can be provided as an Elixir Map, which is internally converted to JSON. The library does not assume anything else regarding the payload and also does not (and will never) provide a magic DSL to generate the payload. That way users can directly manipulate the API data, that is sent to the Elastic server.

## Overview

Elastix has *3 main modules* and one *utility module*, that can be used, if the call/feature you want is not implemented (yet). However – please open issues or provide pull requests so I can improve the software for everybody. The modules are:

* [Elastix.Index](lib/elastix/index.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html)
* [Elastix.Document](lib/elastix/document.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html)
* [Elastix.Search](lib/elastix/search.ex) corresponding to: [this official API Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html)
* and [Elastix.HTTP](lib/elastix/http.ex) – a thin [HTTPotion](https://github.com/myfreeweb/httpotion) wrapper

I will try and provide documentation and examples for all of them with time, for now just consult the source code.

## First example with Ecto

sample configuration in your ```config/config.ex``` file with an sample application named ```ShopApi```:

```elixir
config :shop_api, ShopApi,
  elastic_index_name: "shop_api_#{Mix.env}"
  
config :elastix, Elastix,
  elastic_url: "http://127.0.0.1:9200"
```

start elastix application dependencies (or define it as an application dependency in ```mix.exs```):

```elixir
Elastix.start()

```

create the index somewhere

```elixir
Index.create(Application.config(:elastic_index_name), %{})

```

the create a module, that handles indexing and/or searching your ecto model (maybe I'll provide a behaviour for that in future):

```elixir
defmodule ShopApi.ProductElastix do
  
  def index_name do
    Application.config :elastic_index_name
  end
  
  def index_type do
    "product"
  end
  
  def to_map(product) do
    %{
      name: product.name,
      item_number: product.item_number,
      inserted_at: product.inserted_at,
      updated_at: product.updated_at
    }
  end
  
  def model_mod do
    ShopApi.Product
  end
  
  def index(product) do
    index_data = to_map(product)
    Elastix.Document.index(index_name, index_type, product.id, index_data)
  end
  
  def index_delete(product) do
    Elastix.Document.delete(index_name, index_type, product.id)
  end
  
  def search(search_payload) do
    Elastix.Search.search(index_name, [index_type], search_payload)
  end
end

```

use the module in the model callbacks:

```elixir
defmodule ShopApi.Product do
  use ShopApi.Web, :model
  
  after_insert :index_create
  after_update :index_create
  
  after_delete :index_delete
  
  schema "products" do
    field :name, :string
    field :item_number, :string

    timestamps
  end

  @required_fields ~w(name item_number)
  @optional_fields ~w()

  def index_create(changeset) do
    product = changeset.model
    
    ShopApi.ProductElastix.index product
    
    changeset
  end
  
  def index_delete(changeset) do
    product = changeset.model
    
    ShopApi.ProductElastix.index_delete product
    
    changeset
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end

```

## License

Copyright © 2015 El Werbitzky <werbitzky@gmail.com>
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See [http://www.wtfpl.net/](http://www.wtfpl.net/) for more details.

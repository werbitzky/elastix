defmodule Elastix do
  @moduledoc """
  Elastix consists of several modules trying to match the Elasticsearch API, a
  `Elastix.HTTP` module for raw requests and a `Elastix.JSON` module that allows using a
  custom JSON library.

    - `Elastix.Bulk` -- the [Bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html)
    - `Elastix.Document` -- the [Document API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html)
    - `Elastix.Index` -- the [Index API](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html)
    - `Elastix.Mapping` -- the [Mapping API](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)
    - `Elastix.Search` -- the [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html)
  """

  @doc false
  def start, do: Application.ensure_all_started(:elastix)

  @doc false
  def config, do: Application.get_all_env(:elastix)

  @doc false
  def config(key, default \\ nil), do: Application.get_env(:elastix, key, default)
end

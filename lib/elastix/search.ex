defmodule Elastix.Search do
  @moduledoc """
  The search APIs are used to query indices.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html)
  """
  alias Elastix.{HTTP, JSON}

  @doc """
  Search index based on query.

  Query can be specified as a single map or as a list of maps.

  If a list, uses the [multi search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-multi-search.html)
  to execute several searches from a single API request.

  When passing a map for data, makes a simple search, but you can pass a list of
  header and body params to make a [multi search](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-multi-search.html).

  ## Examples

      iex> query = %{query: %{term: %{user: "kimchy"}}}
      iex> Elastix.Search.search("http://localhost:9200", "twitter", ["tweet"], query)
      {:ok, %HTTPoison.Response{...}}

      iex> query = %{query: %{term: %{user: "kimchy"}}}
      iex> Elastix.Search.search("http://localhost:9200", "twitter", [], query)
      {:ok, %HTTPoison.Response{...}}

  """
  @spec search(binary, binary, list, map | list) :: HTTP.resp
  def search(elastic_url, index, types, query) do
    search(elastic_url, index, types, query, [])
  end

  @doc """
  Search index based on query, with query params and HTTP options.

  See [`HTTPoison.request/5`](https://hexdocs.pm/httpoison/HTTPoison.html#request/5) for options.
  """
  @spec search(binary, binary, list, map | list, Keyword.t, Keyword.t) :: HTTP.resp
  def search(elastic_url, index, types, query, query_params, httpoison_options \\ [])

  def search(elastic_url, index, types, query, query_params, httpoison_options) when is_list(query) do
    url = HTTP.make_url(elastic_url, make_path(index, types, "_msearch"), query_params)
    data = for q <- query, do: [JSON.encode!(q), "\n"]
    headers = [{"Content-Type", "application/x-ndjson"}]
    HTTP.post(url, data, headers, httpoison_options)
  end

  def search(elastic_url, index, types, query, query_params, httpoison_options) when is_map(query) do
    url = HTTP.make_url(elastic_url, make_path(index, types), query_params)
    HTTP.post(url, JSON.encode!(query), [], httpoison_options)
  end

  @doc """
  Search with scrolling through results.

  See the [Scroll API docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html).

  ## Examples

      iex> query = %{query: %{term: %{user: "kimchy"}}}, scroll: "1m")
      iex> {:ok, response} = Elastix.Search.search("http://localhost:9200", "twitter", [], query, scroll: "1m")
      iex> scroll_id = response.body["_scroll_id"]
      iex> params = %{scroll: "1m", scroll_id: scroll_id}
      iex> Elastix.Search.scroll("http://localhost:9200", params)
      {:ok, %HTTPoison.Response{...}}

  """
  @spec scroll(binary, map, Keyword.t) :: HTTP.resp
  def scroll(elastic_url, scroll_params, httpoison_options \\ []) do
    url = HTTP.make_url(elastic_url, "_search/scroll")
    HTTP.post(url, JSON.encode!(scroll_params), [], httpoison_options)
  end

  @doc """
  Returns the number of results for a query using count API.

  See [Count API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-count.html).

  ## Examples

      iex> Elastix.Search.count("http://localhost:9200", "twitter", ["tweet"], %{query: %{term: %{user: "kimchy"}}})
      {:ok, %HTTPoison.Response{...}}

  """
  @spec count(binary, binary, list, map) :: HTTP.resp
  def count(elastic_url, index, types, data) do
    count(elastic_url, index, types, data, [])
  end

  @doc """
  Returns the number of results for a query using count API, supporting query params and HTTP options.

  See [`HTTPoison.request/5`](https://hexdocs.pm/httpoison/HTTPoison.html#request/5).
  """
  @spec count(binary, binary, list, map, Keyword.t, Keyword.t) :: HTTP.resp
  def count(elastic_url, index, types, data, query_params, options \\ []) do
    url = HTTP.make_url(elastic_url, make_path(index, types, "_count"), query_params)
    HTTP.post(url, JSON.encode!(data), [], options)
  end

  @doc false
  @spec make_path(binary, [binary], binary) :: binary
  def make_path(index, types, api_type \\ "_search")
  def make_path(index, [], api_type), do: "/#{index}/#{api_type}"
  def make_path(index, types, api_type) do
    types = Enum.join(types, ",")
    "/#{index}/#{types}/#{api_type}"
  end
end

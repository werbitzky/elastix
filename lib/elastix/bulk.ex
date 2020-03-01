defmodule Elastix.Bulk do
  @moduledoc """
  The bulk API performs multiple indexing or delete operations in a single API
  call. This reduces overhead and can greatly increase indexing speed.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html)
  """
  alias Elastix.{HTTP, JSON}

  require Logger

  @doc """
  Send a batch of actions and sources, encoding them as JSON.

  Data should be encoded as a list of maps.
  See the [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html).

  ## Examples

      iex> operations = [%{index: %{_id: "1"}}, %{user: "kimchy"}]
      iex> Elastix.Bulk.post("http://localhost:9200", operations, index: "twitter", type: "tweet")
      {:ok, %HTTPoison.Response{...}}

  """
  @spec post(binary, list, Keyword.t, Keyword.t) :: HTTP.resp
  def post(elastic_url, operations, options \\ [], query_params \\ []) do
    data = for op <- operations, do: [JSON.encode!(op), "\n"]
    post_raw(elastic_url, data, options, query_params)
  end

  @doc """
  Send a list of actions and sources, with data already encoded as JSON.

  Data should be encoded as described in the [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html).

  Options:

  * index: Default index name if actions don't specify one
  * type: Default type if actions don't specify one.
    Type is obsolete in newer versions of Elasticsearch.
    See [removal of mapping types](https://www.elastic.co/guide/en/elasticsearch/reference/current/removal-of-types.html)
  * httpoison_options: options for HTTP call, e.g. setting timeout

  """
  @spec post_raw(binary, iodata, Keyword.t, Keyword.t) :: HTTP.resp
  def post_raw(elastic_url, raw_data, options \\ [], query_params \\ []) do
    url = HTTP.make_url(elastic_url, make_path(options[:index], options[:type]), query_params)
    headers = [{"Content-Type", "application/x-ndjson"}]
    httpoison_options = options[:httpoison_options] || []
    HTTP.post(url, raw_data, headers, httpoison_options)
  end

  @doc deprecated: "Use post/4 instead"
  @spec post_to_iolist(binary, list, Keyword.t, Keyword.t) :: HTTP.resp
  def post_to_iolist(elastic_url, lines, options \\ [], query_params \\ []) do
    Logger.warn("This function is deprecated and will be removed in future releases; use Elastix.Bulk.post/4 instead.")
    httpoison_options = options[:httpoison_options] || []
    url = HTTP.make_url(elastic_url, make_path(options[:index], options[:type]), query_params)
    HTTP.post(url, Enum.map(lines, fn line -> JSON.encode!(line) <> "\n" end), [], httpoison_options)
  end

  @doc false
  # Make path based on index and type options
  @spec make_path(binary | nil, binary | nil) :: binary
  def make_path(index, type)
  def make_path(nil, nil), do: "/_bulk"
  def make_path(index, nil), do: "/#{index}/_bulk"
  def make_path(index, type), do: "/#{index}/#{type}/_bulk"
end

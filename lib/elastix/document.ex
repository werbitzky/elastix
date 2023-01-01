defmodule Elastix.Document do
  @moduledoc """
  The document APIs expose CRUD operations on documents.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html)
  """
  alias Elastix.{HTTP, JSON}

  @doc """
  Index document.

  * `elastic_url`: base url for Elasticsearch server
  * `index`: index name
  * `data`: data to index, either a map or binary
  * `metadata`:
     - id`: document identifier. If not specified, Elasticsearch will generate one.
     - `type`: document type
       Type is obsolete in newer versions of Elasticsearch.
       See [removal of mapping types](https://www.elastic.co/guide/en/elasticsearch/reference/current/removal-of-types.html)

  ## Examples

  New API:

      iex> data = %{user: "kimchy", post_date: "2009-11-15T14:12:12", message: "trying out Elastix"}
      iex> index = "twitter"
      iex> Elastix.Document.index("http://localhost:9200", index, data, %{id: "42", type: "tweet"})
      {:ok, %HTTPoison.Response{...}}

  Old API:

      iex> data = %{user: "kimchy", post_date: "2009-11-15T14:12:12", message: "trying out Elastix"}
      iex> index = "twitter"
      iex> type = "tweet"
      iex> id = "42"
      iex> Elastix.Document.index("http://localhost:9200", index, type, id, data)
      {:ok, %HTTPoison.Response{...}}

  """
  # New: @spec index(binary, binary, map | binary, map | binary, Keyword.t) :: HTTP.resp
  def index(elastic_url, index, data_or_type, metadata_or_id \\ %{}, data_or_query_params \\ [], query_params \\ [])

  # New: @spec index(binary, binary, binary | map, map, Keyword.t) :: HTTP.resp
  def index(elastic_url, index, data, %{id: _} = metadata, query_params, _unused) when is_map(metadata) do
    url = HTTP.make_url(elastic_url, make_path(index, metadata), query_params)
    HTTP.put(url, JSON.encode!(data))
  end
  def index(elastic_url, index, data, metadata, query_params, _unused) when is_map(metadata) do
    url = HTTP.make_url(elastic_url, make_path(index, metadata), query_params)
    HTTP.post(url, JSON.encode!(data)) # Use post to automatically assign id when not specified
  end

  # Old: @spec index(binary, binary, binary, binary, map, Keyword.t) :: HTTP.resp
  def index(elastic_url, index, type, id, data, query_params) do
    # TODO: Deprecation warning
    url = HTTP.make_url(elastic_url, make_path_old(index, type, query_params, id))
    HTTP.put(url, JSON.encode!(data))
  end

  # @doc deprecated: """
  # Index a new document.
  #
  # ## Examples
  #
  #     iex> data = %{user: "kimchy", post_date: "2009-11-15T14:12:12", message: "trying out Elastix"}
  #     iex> Elastix.Document.index_new("http://localhost:9200", "twitter", "tweet", data)
  #     {:ok, %HTTPoison.Response{...}}
  # """
  @doc deprecated: "Use index/6 instead"
  @spec index_new(binary, binary, binary, map, Keyword.t) :: HTTP.resp
  def index_new(elastic_url, index, type, data, query_params \\ []) do
    # TODO: deprecation warning
    url = HTTP.make_url(elastic_url, make_path_old(index, type, query_params))
    HTTP.post(url, JSON.encode!(data))
  end

  @doc """
  Get document by id.

  ## Examples

  New API without types:

      iex> Elastix.Document.get("http://localhost:9200", "twitter", "42")
      {:ok, %HTTPoison.Response{...}}

  Old API with types:

      iex> Elastix.Document.get("http://localhost:9200", "twitter", "tweet", "42")
      {:ok, %HTTPoison.Response{...}}

  """
  @spec get(binary, binary, binary, Keyword.t | binary, Keyword.t) :: HTTP.resp

  def get(elastic_url, index, id_or_type, query_params_or_id \\ [], query_params \\ [])

  # New API
  def get(elastic_url, index, id, query_params, _unused) when is_list(query_params) do
    url = HTTP.make_url(elastic_url, make_path(index, %{id: id}), query_params)
    HTTP.get(url)
  end

  # Old: @spec get(binary, binary, binary, binary, Keyword.t) :: HTTP.resp
  def get(elastic_url, index, type, id, query_params) do
    # TODO: deprecation warning
    url = HTTP.make_url(elastic_url, make_path_old(index, type, query_params, id))
    HTTP.get(url)
  end


  @doc """
  Get multiple documents with the mget API.

  [Multi Get API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-multi-get.html).
  """

  @spec mget(binary, map, binary | nil, binary | Keyword.t, Keyword.t) :: HTTP.resp
  # Old: @spec mget(binary, map, binary | nil, binary | nil, Keyword.t) :: HTTP.resp

  def mget(elastic_url, query, index \\ nil, query_params_or_type \\ [], query_params \\ [])

  # New API
  def mget(elastic_url, query, nil, query_params, _unused) when is_list(query_params) do
    do_mget(elastic_url, query, ["_mget"], query_params)
  end
  def mget(elastic_url, query, index, query_params, _unused) when is_list(query_params) do
    do_mget(elastic_url, query, [index, "_mget"], query_params)
  end

  # Old API
  def mget(elastic_url, query, index, type, query_params) when is_binary(type) do
    do_mget(elastic_url, query, [index, type, "_mget"], query_params)
  end

  defp do_mget(elastic_url, query, path_comps, query_params) do
    url = HTTP.make_url(elastic_url, path_comps, query_params)
    # HTTPoison does not provide an API for a GET request with a body.
    HTTP.request(:get, url, JSON.encode!(query))
  end

  @doc """
  Delete the documents matching the given `id`.

  ## Examples

      iex> Elastix.Document.delete("http://localhost:9200", "twitter", "tweet", "42")
      {:ok, %HTTPoison.Response{...}}

  """
  @spec delete(binary, binary, binary, Keyword.t | binary, Keyword.t) :: HTTP.resp

  def delete(elastic_url, index, type_or_id, id_or_query_params \\ [], query_params \\ [])

  def delete(elastic_url, index, id, query_params, _unused) when is_list(query_params) do
    url = HTTP.make_url(elastic_url, make_path(index, %{id: id}), query_params)
    HTTP.delete(url)
  end

  # Old: @spec delete(binary, binary, binary, binary, Keyword.t) :: HTTP.resp
  def delete(elastic_url, index, type, id, query_params) when is_binary(id) or is_integer(id) do
    url = HTTP.make_url(elastic_url, make_path_old(index, type, query_params, id))
    HTTP.delete(url)
  end

  @doc """
  Delete the documents matching the given `query` using the
  [Delete By Query API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html).
  """
  @spec delete_matching(binary, binary, map, Keyword.t) :: HTTP.resp
  def delete_matching(elastic_url, index, %{} = query, query_params \\ []) do
    url = HTTP.make_url(elastic_url, [index, "_delete_by_query"], query_params)
    HTTP.post(url, JSON.encode!(query))
  end

  @doc """
  Update the document with the given `id`.

  ## Examples

      iex> data = %{user: "kimchy", message: "trying out Elastix.Document.update/5"}
      iex> Elastix.Document.update("http://localhost:9200", "twitter", "tweet", "42", data)
      {:ok, %HTTPoison.Response{...}}

  """
  @spec update(binary, binary, binary, binary, map, Keyword.t) :: HTTP.resp
  def update(elastic_url, index, type, id, data, query_params \\ []) do
    url = HTTP.make_url(elastic_url, make_path_old(index, type, query_params, id, "_update"))
    HTTP.post(url, JSON.encode!(data))
  end

  @doc """
  Updates the documents matching the given `query` using the
  [Update By Query API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update-by-query.html).

  ## Examples

      iex> Elastix.Document.update_by_query("http://localhost:9200", "twitter", %{"term" => %{"user" => "kimchy"}}, %{inline: "ctx._source.user = 'kimchy updated'", lang: "painless"})
      {:ok, %HTTPoison.Response{...}}
  """
  @spec update_by_query(
          elastic_url :: String.t(),
          index :: String.t(),
          query :: map,
          script :: map,
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def update_by_query(elastic_url, index_name, query, script, query_params \\ []) do
    elastic_url
    |> HTTP.make_url([index_name, "_update_by_query"])
    |> HTTP.add_query_params(query_params)
    |> HTTP.post(
      JSON.encode!(%{
        script: script,
        query: query
      })
    )
  end

  @doc false
  @spec make_path(binary, map) :: binary
  def make_path(index, metadata \\ %{})
  def make_path(index, %{id: id}), do: "/#{index}/_doc/#{id}"
  def make_path(index, %{_id: id}), do: "/#{index}/_doc/#{id}"
  def make_path(index, _), do: "/#{index}/_doc/"

  @doc false
  def make_path_old(index, type, query_params) do
    HTTP.add_query_params("/#{index}/#{type}", query_params)
  end

  @doc false
  def make_path_old(index, type, query_params, id, suffix \\ nil)
  def make_path_old(index, type, query_params, id, nil) do
    HTTP.add_query_params("/#{index}/#{type}/#{id}", query_params)
  end
  def make_path_old(index, type, query_params, id, suffix) do
    HTTP.add_query_params("/#{index}/#{type}/#{id}/#{suffix}", query_params)
  end

end

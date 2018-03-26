defmodule Elastix.Document do
  @moduledoc """
  The document APIs expose CRUD operations on documents.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html)
  """
  import Elastix.HTTP, only: [prepare_url: 2]
  alias Elastix.{HTTP, JSON}

  @doc """
  (Re)Indexes a document with the given `id`.

  ## Examples

      iex> Elastix.Document.index("http://localhost:9200", "twitter", "tweet", "42", %{user: "kimchy", post_date: "2009-11-15T14:12:12", message: "trying out Elastix"})
      {:ok, %HTTPoison.Response{...}}
  """
  @spec index(
          elastic_url :: String.t(),
          index :: String.t(),
          type :: String.t(),
          id :: String.t(),
          data :: map,
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def index(elastic_url, index_name, type_name, id, data, query_params \\ []) do
    prepare_url(elastic_url, make_path(index_name, type_name, query_params, id))
    |> HTTP.put(JSON.encode!(data))
  end

  @doc """
  Indexes a new document.

  ## Examples

      iex> Elastix.Document.index_new("http://localhost:9200", "twitter", "tweet", %{user: "kimchy", post_date: "2009-11-15T14:12:12", message: "trying out Elastix"})
      {:ok, %HTTPoison.Response{...}}
  """
  @spec index_new(
          elastic_url :: String.t(),
          index :: String.t(),
          type :: String.t(),
          data :: map,
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def index_new(elastic_url, index_name, type_name, data, query_params \\ []) do
    prepare_url(elastic_url, make_path(index_name, type_name, query_params))
    |> HTTP.post(JSON.encode!(data))
  end

  @doc """
  Fetches a document matching the given `id`.

  ## Examples

      iex> Elastix.Document.get("http://localhost:9200", "twitter", "tweet", "42")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec get(
          elastic_url :: String.t(),
          index :: String.t(),
          type :: String.t(),
          id :: String.t(),
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def get(elastic_url, index_name, type_name, id, query_params \\ []) do
    prepare_url(elastic_url, make_path(index_name, type_name, query_params, id))
    |> HTTP.get
  end

  @doc """
  Fetches multiple documents matching the given `query` using the
  [Multi Get API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-multi-get.html).
  """
  @spec mget(
          elastic_url :: String.t(),
          query :: map,
          index :: String.t(),
          type :: String.t(),
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def mget(elastic_url, query, index_name \\ nil, type_name \\ nil, query_params \\ []) do
    path = [index_name, type_name]
      |> Enum.filter(fn v -> v end) # Filter out nils.
      |> Enum.join("/")

    url =
      prepare_url(elastic_url, [path, "_mget"])
      |> HTTP.append_query_string(query_params)

    # HTTPoison does not provide an API for a GET request with a body.
    HTTP.request(:get, url, JSON.encode!(query))
  end

  @doc """
  Deletes the documents matching the given `id`.

  ## Examples

      iex> Elastix.Document.delete("http://localhost:9200", "twitter", "tweet", "42")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec delete(
          elastic_url :: String.t(),
          index :: String.t(),
          type :: String.t(),
          id :: String.t(),
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def delete(elastic_url, index_name, type_name, id, query_params \\ []) do
    prepare_url(elastic_url, make_path(index_name, type_name, query_params, id))
    |> HTTP.delete
  end

  @doc """
  Deletes the documents matching the given `query` using the
  [Delete By Query API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html).
  """
  @spec delete_matching(
          elastic_url :: String.t(),
          index :: String.t(),
          query :: map,
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def delete_matching(elastic_url, index_name, %{} = query, query_params \\ []) do
    prepare_url(elastic_url, [index_name, "_delete_by_query"])
    |> HTTP.append_query_string(query_params)
    |> HTTP.post(JSON.encode!(query))
  end

  @doc """
  Updates the document with the given `id`.

  ## Examples

      iex> Elastix.Document.update("http://localhost:9200", "twitter", "tweet", "42", %{user: "kimchy", message: "trying out Elastix.Document.update/5"})
      {:ok, %HTTPoison.Response{...}}
  """
  @spec update(
          elastic_url :: String.t(),
          index :: String.t(),
          type :: String.t(),
          id :: String.t(),
          data :: map,
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def update(elastic_url, index_name, type_name, id, data, query_params \\ []) do
    elastic_url
    |> prepare_url(make_path(index_name, type_name, query_params, id, "_update"))
    |> HTTP.post(JSON.encode!(data))
  end

  @doc false
  def make_path(index_name, type_name, query_params) do
    "/#{index_name}/#{type_name}"
    |> HTTP.append_query_string(query_params)
  end

  @doc false
  def make_path(index_name, type_name, query_params, id, suffix \\ nil) do
    "/#{index_name}/#{type_name}/#{id}/#{suffix}"
    |> HTTP.append_query_string(query_params)
  end
end

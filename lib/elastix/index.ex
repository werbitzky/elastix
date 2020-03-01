defmodule Elastix.Index do
  @moduledoc """
  The indices APIs are used to manage individual indices, index settings,
  aliases, mappings, and index templates.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html)
  """
  alias Elastix.{HTTP, JSON}

  @doc """
  Create a new index.

  ## Examples

      iex> Elastix.Index.create("http://localhost:9200", "twitter", %{})
      {:ok, %HTTPoison.Response{...}}

  """
  @spec create(binary, binary, map) :: HTTP.resp
  def create(elastic_url, index, data) do
    url = HTTP.make_url(elastic_url, index)
    HTTP.put(url, JSON.encode!(data))
  end

  @doc """
  Delete an existing index.

  ## Examples

      iex> Elastix.Index.delete("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}

  """
  @spec delete(binary, binary) :: HTTP.resp
  def delete(elastic_url, index) do
    url = HTTP.make_url(elastic_url, index)
    HTTP.delete(url)
  end

  @doc """
  Fetches info about an existing index.

  ## Examples

      iex> Elastix.Index.get("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}

  """
  @spec get(binary, binary) :: HTTP.resp
  def get(elastic_url, index) do
    url = HTTP.make_url(elastic_url, index)
    HTTP.get(url)
  end

  @doc """
  Check if index exists.

  Returns `{:ok, true}` if the index exists.

  ## Examples

      iex> Elastix.Index.exists?("http://localhost:9200", "twitter")
      {:ok, false}

      iex> Elastix.Index.create("http://localhost:9200", "twitter", %{})
      {:ok, %HTTPoison.Response{...}}

      iex> Elastix.Index.exists?("http://localhost:9200", "twitter")
      {:ok, true}

  """
  @spec exists?(binary, binary) :: {:ok, boolean} | {:error, HTTPoison.Error.t}
  def exists?(elastic_url, index) do
    url = HTTP.make_url(elastic_url, index)
    case HTTP.head(url) do
      {:ok, %{status_code: 200}} -> {:ok, true}
      {:ok, %{status_code: 404}} -> {:ok, false}
      err -> err
    end
  end

  @doc """
  Force refresh of index.

  [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html)

  ## Examples

      iex> Elastix.Index.refresh("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}

  """
  @spec refresh(binary, binary) :: HTTP.resp
  def refresh(elastic_url, index) do
    url = HTTP.make_url(elastic_url, [index, "_refresh"])
    HTTP.post(url, "")
  end

  @doc """
  Open index.

  [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-open-close.html)

  ## Examples

      iex> Elastix.Index.open("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}

  """
  @spec open(binary, binary) :: HTTP.resp
  def open(elastic_url, index) do
    url = HTTP.make_url(elastic_url, [index, "_open"])
    HTTP.post(url, "")
  end

  @doc """
  Close index.

  [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-open-close.html)

  ## Examples

      iex> Elastix.Index.close("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}

  """
  @spec close(binary, binary) :: HTTP.resp
  def close(elastic_url, index) do
    url = HTTP.make_url(elastic_url, [index, "_close"])
    HTTP.post(url, "")
  end
end

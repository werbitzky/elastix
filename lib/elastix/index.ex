defmodule Elastix.Index do
  @moduledoc """
  The indices APIs are used to manage individual indices, index settings, aliases, mappings, and index templates.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html)
  """
  import Elastix.HTTP, only: [prepare_url: 2]
  alias Elastix.{HTTP, JSON}

  @doc """
  Creates a new index.

  ## Examples

      iex> Elastix.Index.create("http://localhost:9200", "twitter", %{})
      {:ok, %HTTPoison.Response{...}}
  """
  @spec create(elastic_url :: String.t(), name :: String.t(), data :: map) :: HTTP.resp()
  def create(elastic_url, name, data) do
    prepare_url(elastic_url, name)
    |> HTTP.put(JSON.encode!(data))
  end

  @doc """
  Deletes an existing index.

  ## Examples

      iex> Elastix.Index.delete("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec delete(elastic_url :: String.t(), name :: String.t()) :: HTTP.resp()
  def delete(elastic_url, name) do
    prepare_url(elastic_url, name)
    |> HTTP.delete
  end

  @doc """
  Fetches info about an existing index.

  ## Examples

      iex> Elastix.Index.get("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec get(elastic_url :: String.t(), name :: String.t()) :: HTTP.resp()
  def get(elastic_url, name) do
    prepare_url(elastic_url, name)
    |> HTTP.get
  end

  @doc """
  Returns `true` if the specified index exists, `false` otherwise.

  ## Examples

      iex> Elastix.Index.exists?("http://localhost:9200", "twitter")
      {:ok, false}
      iex> Elastix.Index.create("http://localhost:9200", "twitter", %{})
      {:ok, %HTTPoison.Response{...}}
      iex> Elastix.Index.exists?("http://localhost:9200", "twitter")
      {:ok, true}
  """
  @spec exists?(elastic_url :: String.t(), name :: String.t()) :: HTTP.resp()
  def exists?(elastic_url, name) do
    case prepare_url(elastic_url, name) |> HTTP.head do
      {:ok, response} ->
        case response.status_code do
          200 -> {:ok, true}
          404 -> {:ok, false}
        end
      err -> err
    end
  end

  @doc """
  Forces the [refresh](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html)
  of the specified index.

  ## Examples

      iex> Elastix.Index.refresh("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec refresh(elastic_url :: String.t(), name :: String.t()) :: HTTP.resp()
  def refresh(elastic_url, name) do
    prepare_url(elastic_url, [name, "_refresh"])
    |> HTTP.post("")
  end

  @doc """
  [Opens](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-open-close.html)
  the specified index.

  ## Examples

      iex> Elastix.Index.open("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec open(elastic_url :: String.t(), name :: String.t()) :: HTTP.resp()
  def open(elastic_url, name) do
    prepare_url(elastic_url, [name, "_open"])
    |> HTTP.post("")
  end

  @doc """
  [Closes](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-open-close.html)
  the specified index.

  ## Examples

      iex> Elastix.Index.close("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec close(elastic_url :: String.t(), name :: String.t()) :: HTTP.resp()
  def close(elastic_url, name) do
    prepare_url(elastic_url, [name, "_close"])
    |> HTTP.post("")
  end
end

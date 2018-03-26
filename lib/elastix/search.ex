defmodule Elastix.Search do
  @moduledoc """
  The search APIs are used to query indices.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html)
  """
  import Elastix.HTTP, only: [prepare_url: 2]
  alias Elastix.{HTTP, JSON}

  @doc """
  Makes a request to the `_search` or the `_msearch` endpoint depending on the type of
  `data`.

  When passing a map for data, it'll make a simple search, but you can pass a list of
  header and body params to make a [multi search](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-multi-search.html).

  ## Examples

      iex> Elastix.Search.search("http://localhost:9200", "twitter", ["tweet"], %{query: %{term: %{user: "kimchy"}}})
      {:ok, %HTTPoison.Response{...}}
  """
  @spec search(
          elastic_url :: String.t(),
          index :: String.t(),
          types :: list,
          data :: map | list
        ) :: HTTP.resp()
  def search(elastic_url, index, types, data) when is_list(data),
    do: search(elastic_url, index, types, data, [])

  def search(elastic_url, index, types, data),
    do: search(elastic_url, index, types, data, [])

  @doc """
  Same as `search/4` but allows to specify query params and options for
  [`HTTPoison.request/5`](https://hexdocs.pm/httpoison/HTTPoison.html#request/5).
  """
  @spec search(
          elastic_url :: String.t(),
          index :: String.t(),
          types :: list,
          data :: map | list,
          query_params :: Keyword.t(),
          options :: Keyword.t()
        ) :: HTTP.resp()
  def search(elastic_url, index, types, data, query_params, options \\ [])

  def search(elastic_url, index, types, data, query_params, options)
      when is_list(data) do
    data =
      Enum.reduce(data, [], fn d, acc -> ["\n", JSON.encode!(d) | acc] end)
      |> Enum.reverse()
      |> IO.iodata_to_binary()

    prepare_url(elastic_url, make_path(index, types, query_params, "_msearch"))
    |> HTTP.post(data, [], options)
  end

  def search(elastic_url, index, types, data, query_params, options) do
    prepare_url(elastic_url, make_path(index, types, query_params))
    |> HTTP.post(JSON.encode!(data), [], options)
  end

  @doc """
  Uses the [Scroll API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html)
  to allow scrolling through a list of results.

  ## Examples

      iex> Elastix.Search.scroll("http://localhost:9200", %{query: %{term: %{user: "kimchy"}}})
      {:ok, %HTTPoison.Response{...}}
  """
  @spec scroll(elastic_url :: String.t(), data :: map, options :: Keyword.t()) ::
          HTTP.resp()
  def scroll(elastic_url, data, options \\ []) do
    prepare_url(elastic_url, "_search/scroll")
    |> HTTP.post(JSON.encode!(data), [], options)
  end

  @doc """
  Returns the number of results for a query using the
  [Count API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-count.html).

  ## Examples

      iex> Elastix.Search.count("http://localhost:9200", "twitter", ["tweet"], %{query: %{term: %{user: "kimchy"}}})
      {:ok, %HTTPoison.Response{...}}
  """
  @spec count(elastic_url :: String.t(), index :: String.t(), types :: list, data :: map) ::
          HTTP.resp()
  def count(elastic_url, index, types, data),
    do: count(elastic_url, index, types, data, [])

  @doc """
  Same as `count/4` but allows to specify query params and options for
  [`HTTPoison.request/5`](https://hexdocs.pm/httpoison/HTTPoison.html#request/5).
  """
  @spec count(
          elastic_url :: String.t(),
          index :: String.t(),
          types :: list,
          data :: map,
          query_params :: Keyword.t(),
          options :: Keyword.t()
        ) :: HTTP.resp()
  def count(elastic_url, index, types, data, query_params, options \\ []) do
    elastic_url <> make_path(index, types, query_params, "_count")
    |> HTTP.post(JSON.encode!(data), [], options)
  end

  @doc false
  def make_path(index, types, query_params, api_type \\ "_search") do
    path_root = "/#{index}"

    path = case types do
      [] -> path_root
      _ -> path_root <> "/" <> Enum.join types, ","
    end

    full_path = "#{path}/#{api_type}"

    case query_params do
      [] -> full_path
      _ -> HTTP.append_query_string(full_path, query_params)
    end
  end
end

defmodule Elastix.Mapping do
  @moduledoc """
  The mapping API is used to define how documents are stored and indexed.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)
  """
  import Elastix.HTTP, only: [prepare_url: 2]

  alias Elastix.HTTP
  alias Elastix.JSON

  @doc """
  Creates a new mapping.

  ## Examples

      iex> mapping = %{properties: %{user: %{type: "text"}, post_date: %{type: "date"}, message: %{type: "text"}}}
      iex> Elastix.Mapping.put("http://localhost:9200", "twitter", "tweet", mapping)
      {:ok, %HTTPoison.Response{...}}
  """
  @spec put(
          elastic_url :: String.t(),
          index_names :: String.t() | list,
          type_name :: String.t(),
          data :: map,
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def put(elastic_url, index_names, type_name, data, query_params \\ [])

  def put(elastic_url, index_names, type_name, data, query_params) when is_list(index_names) do
    elastic_url
    |> prepare_url(make_path(index_names, [type_name], query_params))
    |> HTTP.put(JSON.encode!(data))
  end

  def put(elastic_url, index_name, type_name, data, query_params),
    do: put(elastic_url, [index_name], type_name, data, query_params)

  @doc """
  Gets info on one or a list of mappings for one or a list of indices.

  ## Examples

      iex> Elastix.Mapping.get("http://localhost:9200", "twitter", "tweet")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec get(
          elastic_url :: String.t(),
          index_names :: String.t() | list,
          type_names :: String.t() | list,
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def get(elastic_url, index_names, type_names, query_params \\ [])

  def get(elastic_url, index_names, type_names, query_params) when is_list(type_names) and is_list(index_names) do
    elastic_url
    |> prepare_url(make_path(index_names, type_names, query_params))
    |> HTTP.get()
  end

  def get(elastic_url, index_names, type_name, query_params) when is_list(index_names) do
    get(elastic_url, index_names, [type_name], query_params)
  end

  def get(elastic_url, index_name, type_names, query_params) when is_list(type_names) do
    get(elastic_url, [index_name], type_names, query_params)
  end

  def get(elastic_url, index_name, type_name, query_params),
    do: get(elastic_url, [index_name], [type_name], query_params)

  @doc """
  Gets info on every mapping.

  ## Examples

      iex> Elastix.Mapping.get_all("http://localhost:9200")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec get_all(elastic_url :: String.t(), query_params :: Keyword.t()) :: HTTP.resp()
  def get_all(elastic_url, query_params \\ []) do
    elastic_url
    |> prepare_url(make_all_path(query_params))
    |> HTTP.get()
  end

  @doc """
  Gets info on every given mapping.

  ## Examples

      iex> Elastix.Mapping.get_all("http://localhost:9200", ["tweet", "user"])
      {:ok, %HTTPoison.Response{...}}
  """
  @spec get_all_with_type(
          elastic_url :: String.t(),
          type_names :: String.t() | list,
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def get_all_with_type(elastic_url, type_names, query_params \\ [])

  def get_all_with_type(elastic_url, type_names, query_params) when is_list(type_names) do
    elastic_url
    |> prepare_url(make_all_path(type_names, query_params))
    |> HTTP.get()
  end

  def get_all_with_type(elastic_url, type_name, query_params),
    do: get_all_with_type(elastic_url, [type_name], query_params)

  @doc false
  def make_path(index_names, type_names, query_params) do
    index_names = Enum.join(index_names, ",")
    type_names = Enum.join(type_names, ",")

    path = "/#{index_names}/_mapping/#{type_names}"

    case query_params do
      [] -> path
      _ -> HTTP.append_query_string(path, query_params)
    end
  end

  @doc false
  def make_all_path(query_params) do
    path = "/_mapping"

    case query_params do
      [] -> path
      _ -> HTTP.append_query_string(path, query_params)
    end
  end

  @doc false
  def make_all_path(type_names, query_params) do
    type_names = Enum.join(type_names, ",")

    path = "/_mapping/#{type_names}"

    case query_params do
      [] -> path
      _ -> HTTP.append_query_string(path, query_params)
    end
  end
end

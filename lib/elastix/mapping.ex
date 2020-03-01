defmodule Elastix.Mapping do
  @moduledoc """
  The mapping API is used to define how documents are stored and indexed.

  [Elastic docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)

  [Removal of mapping types](https://www.elastic.co/guide/en/elasticsearch/reference/current/removal-of-types.html)

  """
  alias Elastix.{HTTP, JSON}

  @doc """
  Add field to an existing mapping.

  [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html#add-field-mapping)

  ## Examples

  New API

      iex> mappings = %{properties: %{user: %{type: "text"}, post_date: %{type: "date"}, message: %{type: "text"}}}
      iex> Elastix.Mapping.put("http://localhost:9200", "twitter", mappings)
      {:ok, %HTTPoison.Response{...}}

  Old API with mapping types

      iex> mappings = %{properties: %{user: %{type: "text"}, post_date: %{type: "date"}, message: %{type: "text"}}}
      iex> Elastix.Mapping.put("http://localhost:9200", "twitter", "tweet", mappings)
      {:ok, %HTTPoison.Response{...}}

  """
  # Support the old Elasticsearch API with mapping types and the new API
  # without mapping types using the same natural function name.
  @spec put(binary, binary | [binary], binary | map, map | Keyword.t, Keyword.t) :: HTTP.resp

  def put(elastic_url, index, type_or_mappings, mappings_or_query_params \\ [], query_params \\ [])

  # Old: @spec put(binary, binary | [binary], binary, map, Keyword.t) :: HTTP.resp
  def put(elastic_url, indexes, type, mappings, query_params) when is_binary(type) do
    url = HTTP.make_url(elastic_url, put_path(indexes, type, mappings, query_params))
    HTTP.put(url, JSON.encode!(mappings))
  end

  # New: @spec put(binary, binary, map, Keyword.t) :: HTTP.resp
  def put(elastic_url, index, mappings, query_params, unused) when is_map(mappings) do
    # New API
    url = HTTP.make_url(elastic_url, put_path(index, mappings, query_params, unused))
    HTTP.put(url, JSON.encode!(mappings))
  end

  @doc false
  @spec put_path(binary | [binary], binary | map, map | Keyword.t, Keyword.t) :: binary
  def put_path(indexes, type_or_mappings, mappings_or_query_params \\ [], query_params \\ [])
  # Old
  def put_path(indexes, type, mappings, query_params) when is_list(indexes) and is_binary(type) do
    indexes = Enum.join(indexes, ",")
    put_path(indexes, type, mappings, query_params)
  end
  def put_path(indexes, type, _mappings, query_params) when is_binary(type) do
    path = "/#{indexes}/_mapping/#{type}"
    HTTP.add_query_params(path, query_params)
  end
  # New
  def put_path(index, mappings, query_params, _unused) when is_map(mappings) do
    path = "/#{index}/_mapping"
    HTTP.add_query_params(path, query_params)
  end

  @doc """
  Get mappings for index.

  [New Elasticsearch API](https://www.elastic.co/guide/en/elasticsearch/reference/6.8/mapping.html)

  [Old Elasticsearch API](https://www.elastic.co/guide/en/elasticsearch/reference/5.5/mapping.html)

  Accepts a single index or list of indexes.
  Accepts a single type or list of types.

  https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html#view-mapping

  ## Examples

      iex> Elastix.Mapping.get("http://localhost:9200", "twitter")
      {:ok, %HTTPoison.Response{...}}

      iex> Elastix.Mapping.get("http://localhost:9200", "twitter", "tweet")
      {:ok, %HTTPoison.Response{...}}

  """
  @spec get(binary, binary | [binary], binary | [binary] | Keyword.t, Keyword.t) :: HTTP.resp
  # New: @spec get(binary, binary, Keyword.t, Keyword.t) :: HTTP.resp
  # Old: @spec get(binary, binary | [binary], binary | [binary], Keyword.t) :: HTTP.resp
  def get(elastic_url, indexes, types_or_query_params \\ [], query_params \\ []) do
    url = HTTP.make_url(elastic_url, get_path(indexes, types_or_query_params, query_params))
    HTTP.get(url)
  end

  @spec get_path(binary | [binary], binary | [binary] | Keyword.t, Keyword.t) :: binary
  # New: @spec get(binary, Keyword.t, Keyword.t) :: binary
  def get_path(index, [], []) when is_binary(index) do
    "/#{index}/_mapping"
  end
  def get_path(index, [value | _rest] = query_params, []) when is_binary(index) and is_tuple(value) do
    HTTP.add_query_params("/#{index}/_mapping", query_params)
  end

  # Old: @spec get(binary | [binary], binary | [binary], Keyword.t) :: binary
  def get_path(indexes, [value | _rest] = types, query_params) when is_list(indexes) and is_binary(value) do
    indexes = Enum.join(indexes, ",")
    types = Enum.join(types, ",")
    HTTP.add_query_params("/#{indexes}/_mapping/#{types}", query_params)
  end
  def get_path(indexes, type, query_params) when is_list(indexes) and is_binary(type) do
    indexes = Enum.join(indexes, ",")
    HTTP.add_query_params("/#{indexes}/_mapping/#{type}", query_params)
  end
  def get_path(index, [value | _rest] = types, query_params) when is_binary(index) and is_binary(value) do
    types = Enum.join(types, ",")
    HTTP.add_query_params("/#{index}/_mapping/#{types}", query_params)
  end
  def get_path(index, type, query_params) when is_binary(index) and is_binary(type) do
    HTTP.add_query_params("/#{index}/_mapping/#{type}", query_params)
  end

  @doc """
  Get info on all mappings.

  ## Examples

      iex> Elastix.Mapping.get_all("http://localhost:9200")
      {:ok, %HTTPoison.Response{...}}

  """
  @spec get_all(binary, Keyword.t) :: HTTP.resp
  def get_all(elastic_url, query_params \\ []) do
    url = HTTP.make_url(elastic_url, "_mapping", query_params)
    HTTP.get(url)
  end

  @doc """
  Get info on all mappings for types.

  ## Examples

      iex> Elastix.Mapping.get_all_with_type("http://localhost:9200", ["tweet", "user"])
      {:ok, %HTTPoison.Response{...}}

  """
  @spec get_all_with_type(binary, [binary], Keyword.t) :: HTTP.resp
  def get_all_with_type(elastic_url, types, query_params \\ []) do
    url = HTTP.make_url(elastic_url, make_all_path(types), query_params)
    HTTP.get(url)
  end

  @doc false
  @spec make_all_path([binary]) :: binary
  def make_all_path(types) when is_list(types) do
    types = Enum.join(types, ",")
    "/_mapping/#{types}"
  end

end

defmodule Elastix.Bulk do
  @moduledoc """
  The bulk API makes it possible to perform many index/delete operations in a single API call.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html)
  """
  import Elastix.HTTP, only: [prepare_url: 2]
  alias Elastix.{HTTP, JSON}

  @doc """
  Excepts a list of actions and sources for the `lines` parameter.

  ## Examples

      iex> Elastix.Bulk.post("http://localhost:9200", [%{index: %{_id: "1"}}, %{user: "kimchy"}], index: "twitter", type: "tweet")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec post(
          elastic_url :: String.t(),
          lines :: list,
          opts :: Keyword.t(),
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def post(elastic_url, lines, options \\ [], query_params \\ []) do
    elastic_url
    |> prepare_url(make_path(
      Keyword.get(options, :index), Keyword.get(options, :type), query_params))
    |> HTTP.put(
      Enum.reduce(
        lines, "",
        fn (line, payload) -> payload <> JSON.encode!(line) <> "\n" end))
  end

  @doc """
  Deprecated: use `post/4` instead.
  """
  @spec post_to_iolist(
          elastic_url :: String.t(),
          lines :: list,
          opts :: Keyword.t(),
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def post_to_iolist(elastic_url, lines, options \\ [], query_params \\ []) do
    IO.warn(
      "This function is deprecated and will be removed in future releases; use Elastix.Bulk.post/4 instead."
    )

    (elastic_url <>
       make_path(Keyword.get(options, :index), Keyword.get(options, :type), query_params))
    |> HTTP.put(Enum.map(lines, fn line -> JSON.encode!(line) <> "\n" end))
  end

  @doc """
  Same as `post/4` but instead of sending a list of maps you must send raw binary data in
  the format described in the [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html).
  """
  @spec post_raw(
          elastic_url :: String.t(),
          raw_data :: String.t(),
          opts :: Keyword.t(),
          query_params :: Keyword.t()
        ) :: HTTP.resp()
  def post_raw(elastic_url, raw_data, options \\ [], query_params \\ []) do
    elastic_url <> make_path(
      Keyword.get(options, :index), Keyword.get(options, :type), query_params)
    |> HTTP.put(raw_data)
  end

  @doc false
  def make_path(index_name, type_name, query_params) do
    path = _make_base_path(index_name, type_name)

    case query_params do
      [] -> path
      _ -> HTTP.append_query_string(path, query_params)
    end
  end

  defp make_base_path(nil, nil), do: "/_bulk"
  defp make_base_path(index_name, nil), do: "/#{index_name}/_bulk"
  defp make_base_path(index_name, type_name), do: "/#{index_name}/#{type_name}/_bulk"
end

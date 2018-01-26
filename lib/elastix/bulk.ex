defmodule Elastix.Bulk do
  @moduledoc """
  """
  import Elastix.HTTP, only: [prepare_url: 2]
  alias Elastix.{HTTP, JSON}

  def post(elastic_url, lines, options \\ [], query_params \\ []) do
    elastic_url
    |> prepare_url(make_path(
      Keyword.get(options, :index), Keyword.get(options, :type), query_params))
    |> HTTP.put(
      Enum.reduce(
        lines, "",
        fn (line, payload) -> payload <> JSON.encode!(line) <> "\n" end))
  end

  def post_to_iolist(elastic_url, lines, options \\ [], query_params \\ []) do
    elastic_url <> make_path(
      Keyword.get(options, :index), Keyword.get(options, :type), query_params)
    |> HTTP.put(Enum.map(lines, fn line -> JSON.encode!(line) <> "\n" end))
  end

  @doc false
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
      _ -> add_query_params(path, query_params)
    end
  end

  defp _make_base_path(nil, nil), do: "/_bulk"
  defp _make_base_path(index_name, nil), do: "/#{index_name}/_bulk"
  defp _make_base_path(index_name, type_name), do: "/#{index_name}/#{type_name}/_bulk"

  @doc false
  defp add_query_params(path, query_params) do
    query_string = Enum.map_join query_params, "&", fn(param) ->
      "#{elem(param, 0)}=#{elem(param, 1)}"
    end

    "#{path}?#{query_string}"
  end
end

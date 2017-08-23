defmodule Elastix.Search do
  @moduledoc """
  """
  alias Elastix.HTTP

  @doc false
  def search(elastic_url, index, types, data) do
    search(elastic_url, index, types, data, [])
  end

  @doc false
  def search(elastic_url, index, types, data, query_params, options \\ []) do
    elastic_url <> make_path(index, types, query_params)
    |> HTTP.post(Poison.encode!(data), [], options)
  end

  @doc false
  def scroll(elastic_url, data, options \\ []) do
    elastic_url <> "/_search/scroll"
    |> HTTP.post(Poison.encode!(data), [], options)
  end

  @doc false
  def make_path(index, types, query_params) do
    path_root = "/#{index}"

    path = case types do
      [] -> path_root
      _ -> path_root <> "/" <> Enum.join types, ","
    end

    full_path = "#{path}/_search"

    case query_params do
      [] -> full_path
      _ -> add_query_params(full_path, query_params)
    end
  end

  @doc false
  defp add_query_params(path, query_params) do
    query_string = Enum.map_join query_params, "&", fn(param) ->
      "#{elem(param, 0)}=#{elem(param, 1)}"
    end

    "#{path}?#{query_string}"
  end
end

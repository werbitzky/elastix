defmodule Elastix.Search do
  @moduledoc """
  """
  alias Elastix.HTTP

  @doc false
  def search(index, types, data) do
    search(index, types, data, [])
  end

  @doc false
  def search(index, types, data, query_params) do
    path = make_path(index, types, query_params)

    process_response(HTTP.post(path, Poison.encode!(data)))
  end

  @doc false
  def make_path(index, types, query_params) do
    path_root = "/#{index}"

    path = case types do
      [] -> path_root
      _ -> path_root <> "/" <> Enum.join types, ","
    end

    path = "#{path}/_search"

    case query_params do
      [] -> path
      _ -> add_query_params(path, query_params)
    end
  end

  @doc false
  defp add_query_params(path, query_params) do
    query_string = Enum.map_join query_params, "&", fn(param) ->
      "#{elem(param, 0)}=#{elem(param, 1)}"
    end

    "#{path}?#{query_string}"
  end

  @doc false
  defp process_response({_, response}), do: response
end

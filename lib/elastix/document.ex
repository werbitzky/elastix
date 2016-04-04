defmodule Elastix.Document do
  @moduledoc """
  """
  alias Elastix.HTTP

  @doc """
  Update a list of documents using the _bulk endpoint.
  The `documents` structure must have an `id` field.
  """
  def bulk_index(elastic_url, index_name, type_name, documents) do
    json =
      documents
      |> Enum.map(fn d -> bulk_document(index_name, type_name, d) end)
      |> Enum.join("\n")

    elastic_url <> make_path(index_name, type_name, "_bulk", []) 
    |> HTTP.put(json)
    |> process_response
  end

  defp bulk_document(index_name, index_type, doc) do
    [
      %{index: %{_index: index_name, _type: index_type, _id: doc.id }},
      doc
    ]
    |> Enum.map(&Poison.encode!/1)
    |> Enum.join("\n")
  end

  @doc false
  def index(elastic_url, index_name, type_name, id, data) do
    index(elastic_url, index_name, type_name, id, data, [])
  end

  @doc false
  def index(elastic_url, index_name, type_name, id, data, query_params) do
    elastic_url <> make_path(index_name, type_name, id, query_params)
    |> HTTP.put(Poison.encode!(data))
    |> process_response
  end

  @doc false
  def get(elastic_url, index_name, type_name, id) do
    get(elastic_url, index_name, type_name, id, [])
  end

  @doc false
  def get(elastic_url, index_name, type_name, id, query_params) do
    elastic_url <> make_path(index_name, type_name, id, query_params)
    |> HTTP.get
    |> process_response
  end

  @doc false
  def delete(elastic_url, index_name, type_name, id) do
    elastic_url <> make_path(index_name, type_name, id, [])
    |> HTTP.delete
    |> process_response
  end

  @doc false
  def delete(elastic_url, index_name, type_name, id, query_params) do
    elastic_url <> make_path(index_name, type_name, id, query_params)
    |> HTTP.delete
    |> process_response
  end

  @doc false
  def make_path(index_name, type_name, id, query_params) do
    path = "/#{index_name}/#{type_name}/#{id}"

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

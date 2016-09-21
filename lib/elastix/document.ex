defmodule Elastix.Document do
  @moduledoc """
  """
  alias Elastix.HTTP

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
  def index_new(elastic_url, index_name, type_name, data) do
    index_new(elastic_url, index_name, type_name, data, [])
  end

  @doc false
  def index_new(elastic_url, index_name, type_name, data, query_params) do
    elastic_url <> make_path(index_name, type_name, query_params)
    |> HTTP.post(Poison.encode!(data))
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

  @doc "Sends a bulk update request for the given list of documents. Note: each document must contain an `_id` field."
  def bulk_update(elastic_url, index_name, type_name, documents, doc_options \\ %{}) do
    elastic_url <> make_bulk_path(index_name, type_name)
    |> HTTP.post(bulk_update_wrap(documents, doc_options))
    |> process_response
  end

  @doc false
  def bulk_update_wrap(documents, doc_options \\ %{}) do
    Enum.reduce(documents, "", fn(doc, payload) ->
      action = Poison.encode!(%{"update": %{"_id": doc["_id"] || doc[:_id]}}) <> "\n"
      doc = Map.delete(doc, "_id") |> Map.delete(:_id)
      wrapped_doc = Poison.encode!(Map.merge(%{"doc": doc}, doc_options)) <> "\n"

      payload <> action <> wrapped_doc
    end)
  end

  @doc false
  def make_bulk_path(index_name, type_name) do
    "/#{index_name}/#{type_name}/_bulk"
  end

  @doc false
  def make_path(index_name, type_name, id \\ nil, query_params) do
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

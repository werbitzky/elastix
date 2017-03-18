defmodule Elastix.Mapping do
  @moduledoc """
  """
  alias Elastix.HTTP

  @doc false
  def put(elastic_url, index_names, type_name, data) when is_list(index_names) do
    put(elastic_url, index_names, type_name, data, [])
  end

  @doc false
  def put(elastic_url, index_name, type_name, data) do
    put(elastic_url, [index_name], type_name, data, [])
  end

  @doc false
  def put(elastic_url, index_names, type_name, data, query_params) when is_list(index_names) do
    elastic_url <> make_path(index_names, [type_name], query_params)
    |> HTTP.put(Poison.encode!(data))
  end

  @doc false
  def put(elastic_url, index_name, type_name, data, query_params) do
    put(elastic_url, [index_name], type_name, data, query_params)
  end

  @doc false
  def get(elastic_url, index_names, type_names) when is_list(type_names) and is_list(index_names) do
    get(elastic_url, index_names, type_names, [])
  end

  @doc false
  def get(elastic_url, index_name, type_names) when is_list(type_names) do
    get(elastic_url, [index_name], type_names, [])
  end

  @doc false
  def get(elastic_url, index_names, type_name) when is_list(index_names) do
    get(elastic_url, index_names, [type_name], [])
  end

  @doc false
  def get(elastic_url, index_name, type_name) do
    get(elastic_url, [index_name], [type_name], [])
  end

  @doc false
  def get(elastic_url, index_names, type_names, query_params) when is_list(type_names) and is_list(index_names) do
    elastic_url <> make_path(index_names, type_names, query_params)
    |> HTTP.get
  end

  @doc false
  def get(elastic_url, index_names, type_name, query_params) when is_list(index_names) do
    get(elastic_url, index_names, [type_name], query_params)
  end

  @doc false
  def get(elastic_url, index_name, type_names, query_params) when is_list(type_names) do
    get(elastic_url, [index_name], type_names, query_params)
  end

  @doc false
  def get(elastic_url, index_name, type_name, query_params) do
    get(elastic_url, [index_name], [type_name], query_params)
  end

  @doc false
  def get_all(elastic_url) do
    get_all(elastic_url, [])
  end

  @doc false
  def get_all(elastic_url, query_params) do
    elastic_url <> make_all_path(query_params)
    |> HTTP.get
  end

  @doc false
  def get_all_with_type(elastic_url, type_names) when is_list(type_names) do
    get_all_with_type(elastic_url, type_names, [])
  end

  @doc false
  def get_all_with_type(elastic_url, type_name) do
    get_all_with_type(elastic_url, [type_name], [])
  end

  @doc false
  def get_all_with_type(elastic_url, type_names, query_params) when is_list(type_names) do
    elastic_url <> make_all_path(type_names, query_params)
    |> HTTP.get
  end

  @doc false
  def get_all_with_type(elastic_url, type_name, query_params) do
    get_all_with_type(elastic_url, [type_name], query_params)
  end

  @doc false
  def make_path(index_names, type_names, query_params) do
    index_names = Enum.join index_names, ","
    type_names = Enum.join type_names, ","

    path = "/#{index_names}/_mapping/#{type_names}"

    case query_params do
      [] -> path
      _ -> add_query_params(path, query_params)
    end
  end

  @doc false
  def make_all_path(query_params) do
    path = "/_mapping"

    case query_params do
      [] -> path
      _ -> add_query_params(path, query_params)
    end
  end

  @doc false
  def make_all_path(type_names, query_params) do
    type_names = Enum.join type_names, ","

    path = "/_mapping/#{type_names}"

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
end

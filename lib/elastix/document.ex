defmodule Elastix.Document do
  @moduledoc """
  """
  alias Elastix.HTTP

  @doc false
  def index(index_name, type_name, id, data) do
    index(index_name, type_name, id, data, [])
  end
  @doc false
  def index(index_name, type_name, id, data, query_params) do
    path = make_path(index_name, type_name, id, query_params)
    HTTP.put(path, [body: Poison.encode!(data)])
  end
  
  @doc false
  def get(index_name, type_name, id) do
    get(index_name, type_name, id, [])
  end
  @doc false
  def get(index_name, type_name, id, query_params) do
    path = make_path(index_name, type_name, id, query_params)
    
    HTTP.get(path)
  end

  @doc false
  def delete(index_name, type_name, id) do
    path = make_path(index_name, type_name, id, [])
    
    HTTP.delete(path)
  end
  @doc false
  def delete(index_name, type_name, id, query_params) do
    path = make_path(index_name, type_name, id, query_params)
    
    HTTP.delete(path)
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
end

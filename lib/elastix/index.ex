defmodule Elastix.Index do
  @moduledoc """
  """
  alias Elastix.HTTP
  
  @doc false
  def create(name, data) do
    HTTP.post(make_path(name), data)
  end
  
  @doc false
  def delete(name) do
    HTTP.delete(make_path(name))
  end
  
  @doc false
  def get(name) do
    HTTP.get(make_path(name))
  end
  
  @doc false
  def exists?(name) do
    request = HTTP.head(make_path(name))
    
    case request.status_code do
      200 -> true
      404 -> false
    end
  end
  
  def make_path(name) do
    "/" <> name
  end
end

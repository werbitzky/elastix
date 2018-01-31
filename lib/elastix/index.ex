defmodule Elastix.Index do
  @moduledoc """
  """
  import Elastix.HTTP, only: [prepare_url: 2]
  alias Elastix.{HTTP, JSON}

  @doc false
  def create(elastic_url, name, data) do
    prepare_url(elastic_url, name)
    |> HTTP.put(JSON.encode!(data))
  end

  @doc false
  def delete(elastic_url, name) do
    prepare_url(elastic_url, name)
    |> HTTP.delete
  end

  @doc false
  def get(elastic_url, name) do
    prepare_url(elastic_url, name)
    |> HTTP.get
  end

  @doc false
  def exists?(elastic_url, name) do
    case prepare_url(elastic_url, name) |> HTTP.head do
      {:ok, response} ->
        case response.status_code do
          200 -> {:ok, true}
          404 -> {:ok, false}
        end
      err -> err
    end
  end

  @doc false
  def refresh(elastic_url, name) do
    prepare_url(elastic_url, [name, "_refresh"])
    |> HTTP.post("")
  end
end

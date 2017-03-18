defmodule Elastix.Index do
  @moduledoc """
  """
  alias Elastix.HTTP

  @doc false
  def create(elastic_url, name, data) do
    elastic_url <> make_path(name)
    |> HTTP.put(Poison.encode!(data))
  end

  @doc false
  def delete(elastic_url, name) do
    elastic_url <> make_path(name)
    |> HTTP.delete
  end

  @doc false
  def get(elastic_url, name) do
    elastic_url <> make_path(name)
    |> HTTP.get
  end

  @doc false
  def exists?(elastic_url, name) do
    case elastic_url <> make_path(name) |> HTTP.head do
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
    elastic_url <> make_path(name) <> make_path("_refresh")
    |> HTTP.post("")
  end

  @doc false
  def make_path(name) do
    "/#{name}"
  end
end

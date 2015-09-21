defmodule Elastix.Index do
  @moduledoc """
  """
  alias Elastix.HTTP

  @doc false
  def create(name, data) do
    process_response(HTTP.post(make_path(name), Poison.encode!(data)))
  end

  @doc false
  def delete(name) do
    process_response(HTTP.delete(make_path(name), []))
  end

  @doc false
  def get(name) do
    process_response(HTTP.get(make_path(name), []))
  end

  @doc false
  def exists?(name) do
    request = process_response(HTTP.head(make_path(name), []))

    case request.status_code do
      200 -> true
      404 -> false
    end
  end

  @doc false
  def make_path(name) do
    "/#{name}"
  end

  @doc false
  defp process_response(response) do
    {_, response} = response
    response
  end
end

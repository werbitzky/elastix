defmodule Elastix.Index do
  @moduledoc """
  """
  alias Elastix.HTTP

  @doc false
  def create(name, data) do
    name
    |> make_path
    |> HTTP.post(Poison.encode!(data))
    |> process_response
  end

  @doc false
  def delete(name) do
    name
    |> make_path
    |> HTTP.delete
    |> process_response
  end

  @doc false
  def get(name) do
    name
    |> make_path
    |> HTTP.get
    |> process_response
  end

  @doc false
  def exists?(name) do
    request = name
      |> make_path
      |> HTTP.head
      |> process_response

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
  defp process_response({_, response}), do: response
end

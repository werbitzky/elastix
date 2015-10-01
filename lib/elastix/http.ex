defmodule Elastix.HTTP do
  @moduledoc """
  """
  use HTTPoison.Base

  @doc false
  def process_url(path) do
    host <> path
  end

  @doc false
  def process_request_headers(headers) do
    headers
    |> Dict.put(:"Content-Type", "application/json; charset=UTF-8")
  end

  @doc false
  def process_response_body(body) do
    case body |> to_string |> Poison.decode do
      {:error, _} -> body
      {:ok, decoded} -> decoded
    end
  end

  @doc false
  def host, do: Elastix.config(:elastic_url)
end

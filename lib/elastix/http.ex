defmodule Elastix.HTTP do
  @moduledoc """
  """
  use HTTPotion.Base
  
  @doc false
  def process_url(path) do
    host <> path
  end

  @doc false
  def process_request_headers(headers) do
    headers
    |> Dict.put(:"Content-Type", "application/json")
  end

  @doc false
  def process_response_body(body) do
    body = to_string body
    case Poison.decode body do
      {:error, _} -> body
      {:ok, decoded} -> decoded
    end
  end
  
  @doc false
  def host, do: Elastix.config(:elastic_url)
end

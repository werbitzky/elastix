defmodule Elastix.HTTP do
  @moduledoc """
  """
  use HTTPoison.Base

  @doc false
  def process_url(url) do
    url
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
end

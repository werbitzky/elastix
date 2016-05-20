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
    headers = headers
    |> Dict.put(:"Content-Type", "application/json; charset=UTF-8")

    # https://www.elastic.co/guide/en/shield/current/_using_elasticsearch_http_rest_clients_with_shield.html
    username = Elastix.config(:username)
    password = Elastix.config(:password)
    if Elastix.config(:shield) do
      headers = Dict.put(headers, :"Authorization", "Basic " <> Base.encode64("#{username}:#{password}"))
    end
    headers
  end

  @doc false
  def process_response_body(body) do
    case body |> to_string |> Poison.decode do
      {:error, _} -> body
      {:ok, decoded} -> decoded
    end
  end
end

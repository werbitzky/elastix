defmodule Elastix.HTTP do
  @moduledoc """
  """
  use HTTPoison.Base

  @doc false
  def process_url(url, options \\ []) do
    url = to_string(url)

    if Keyword.has_key?(options, :params) do
      url <> "?" <> URI.encode_query(options[:params])
    else
      url
    end
  end

  @doc false
  def request(method, url, body \\ "", headers \\ [], options \\ []) do
    url     = process_url(url, options)
    body    = process_request_body(body)
    headers = process_request_headers(headers, {method, url, body})

    HTTPoison.Base.request(
      __MODULE__,
      method,
      url,
      body,
      headers,
      options,
      &process_status_code/1,
      &process_headers/1,
      &process_response_body/1)
  end


  @doc false
  def process_response_body(""), do: ""
  def process_response_body(body) do
    case body |> to_string() |> Poison.decode(poison_options()) do
      {:error, _} -> body
      {:ok, decoded} -> decoded
    end
  end

  @doc """
  Inject additional headers into request. 
  Authorization headers are delegated to an auth "adapter" module: Elastix.Auth.{Shield, AWSES, None}
  """
  def process_request_headers(headers, request_data \\ nil) do 
    adapter = cond do
      Elastix.config(:shield) -> Elastix.Auth.Shield
      Elastix.config(:aws_es) -> Elastix.Auth.AWSES
      true -> Elastix.Auth.None
    end

    headers
    |> Keyword.put_new(:"Content-Type", "application/json; charset=UTF-8")
    |> adapter.process_headers(request_data)
  end

  defp poison_options do
    Elastix.config(:poison_options, [])
  end
end

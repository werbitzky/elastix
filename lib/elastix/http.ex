defmodule Elastix.HTTP do
  @moduledoc """
  """
  use HTTPoison.Base

  @doc false
  def process_url(url) do
    url
  end

  @doc false
  def request(method, url, body \\ "", headers \\ [], options \\ []) do
    query_url = if Keyword.has_key?(options, :params) do
      url <> "?" <> URI.encode_query(options[:params])
    else
      url
    end
    full_url = process_url(to_string(query_url))
    body = process_request_body(body)

    username = Elastix.config(:username)
    password = Elastix.config(:password)

    content_headers = headers
    |> Keyword.put_new(:"Content-Type", "application/json; charset=UTF-8")

    full_headers = if Elastix.config(:shield) do
      Keyword.put(content_headers, :"Authorization", "Basic " <> Base.encode64("#{username}:#{password}"))
    else
      content_headers
    end

    options = Keyword.merge(default_httpoison_options(), options)
    HTTPoison.Base.request(
      __MODULE__,
      method,
      full_url,
      body,
      full_headers,
      options,
      &process_status_code/1,
      &process_headers/1,
      &process_response_body/1)
  end

  @doc false
  def process_response_body(""), do: ""
  def process_response_body(body) do
    case body |> to_string |> Poison.decode(poison_options()) do
      {:error, _} -> body
      {:ok, decoded} -> decoded
    end
  end

  defp poison_options do
    Elastix.config(:poison_options, [])
  end

  defp default_httpoison_options do
    Elastix.config(:httpoison_options, [])
  end
end

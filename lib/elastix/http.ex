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
    url =
    if Keyword.has_key?(options, :params) do
      url <> "?" <> URI.encode_query(options[:params])
    else
      url
    end
    url = process_url(to_string(url))
    body = process_request_body(body)

    headers = headers
    |> Keyword.put_new(:"Content-Type", "application/json; charset=UTF-8")

    # https://www.elastic.co/guide/en/shield/current/_using_elasticsearch_http_rest_clients_with_shield.html
    username = Elastix.config(:username)
    password = Elastix.config(:password)
    headers = cond do
      Elastix.config(:shield) ->
        Keyword.put(headers, :"Authorization", "Basic " <> Base.encode64("#{username}:#{password}"))
      Elastix.config(:custom_headers) ->
        Elastix.config(:custom_headers).call(%{method: method, url: url,body: body, headers: headers, options: options})
      true ->
        headers
    end

    HTTPoison.Base.request(__MODULE__, method, url, body, headers, options, &process_status_code/1, &process_headers/1, &process_response_body/1)
  end


  @doc false
  def process_response_body(body) do
    case body |> to_string |> Poison.decode(poison_options()) do
      {:error, _} -> body
      {:ok, decoded} -> decoded
    end
  end

  defp poison_options do
    Elastix.config(:poison_options, [])
  end
end

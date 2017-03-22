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
    headers = process_request_headers(headers, auth_endpoint(), {method, url, body})

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
  Include signed authorization header for AWS ElasticSearch.
  """
  def process_request_headers(headers, :aws_es, request_data) do
    signed_request = sign_aws_authorization_header(request_data)

    headers
    |> Keyword.put(:"Authorization", signed_request)
    |> process_request_headers(nil, nil)
  end

  @doc """
  Include authorization header for Shield.
  https://www.elastic.co/guide/en/shield/current/_using_elasticsearch_http_rest_clients_with_shield.html
  """
  def process_request_headers(headers, :shield, _) do
    creds      = "#{Elastix.config(:username)}:#{Elastix.config(:password)}"
    auth_token = "Basic " <> Base.encode64(creds)
    
    headers
    |> Keyword.put(:"Authorization", auth_token)
    |> process_request_headers(nil, nil)
  end

  def process_request_headers(headers, _, _) do 
    Keyword.put_new(headers, :"Content-Type", "application/json; charset=UTF-8")
  end

  defp poison_options do
    Elastix.config(:poison_options, [])
  end

  defp auth_endpoint do
    cond do
      Elastix.config(:shield) -> :shield
      Elastix.config(:aws_es) -> :aws_es
      true -> nil
    end
  end

  # https://github.com/bryanjos/aws_auth
  defp sign_aws_authorization_header({method, url, body}) do
    aws_configs = Elastix.config(:aws_es)
    method      = method |> Atom.to_string() |> String.upcase()

    AWSAuth.sign_authorization_header(
      aws_configs[:access_key], 
      aws_configs[:secret_key], 
      method, 
      url, 
      aws_configs[:region], 
      "es", 
      Map.new, 
      body
    )
  end
end

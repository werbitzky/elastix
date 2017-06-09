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

    full_headers = headers
                   |> add_content_type_header
                   |> add_shield_header
                   |> add_custom_headers(method, full_url, body)

    options = Keyword.merge(default_httpoison_options(), options)
    {m, f, _a} = Elastix.config(:test_request_mfa) || {HTTPoison.Base, :request, []}
    apply(m, f, [
      __MODULE__,
      method,
      full_url,
      body,
      full_headers,
      options,
      &process_status_code/1,
      &process_headers/1,
      &process_response_body/1
    ])
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

  defp add_content_type_header(headers) do
    Keyword.put_new(headers, :"Content-Type", "application/json; charset=UTF-8")
  end

  defp add_shield_header(headers) do
    if Elastix.config(:shield) do
      username = Elastix.config(:username)
      password = Elastix.config(:password)
      encoded  = Base.encode64("#{username}:#{password}")
      Keyword.put(headers, :"Authorization", "Basic " <> encoded)
    else
      headers
    end
  end

  defp add_custom_headers(headers, method, url, body) do
    case Elastix.config(:custom_headers) do
      nil -> headers
      {mod, fun, args} ->
        request = %{method: method, headers: headers, url: url, body: body} 
        case apply(mod, fun, [request | args]) do
          headers when is_list(headers) -> headers
          _ -> raise("custom headers must return a header list (keyword list)")
        end
      _ -> raise("Custom headers accepts a tuple of `{Module, :fun, []}` only.")
    end
  end
end

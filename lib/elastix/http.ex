defmodule Elastix.HTTP do
  @moduledoc """
  A thin [HTTPoison](https://github.com/edgurgel/httpoison) wrapper.
  """
  use HTTPoison.Base
  alias Elastix.JSON

  @type resp :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}

  @doc false
  def prepare_url(url, path) when is_binary(path) do
    "#{url}/"
    |> URI.merge(String.trim_leading(path, "/"))
    |> to_string
  end

  def prepare_url(url, parts) when is_list(parts),
    do: prepare_url("#{url}/", Path.join(parts))

  @doc false
  def request(method, url, body \\ "", headers \\ [], options \\ []) do
    query_url =
      if Keyword.has_key?(options, :params) do
        url <> "?" <> URI.encode_query(options[:params])
      else
        url
      end

    full_url = to_string(query_url)
    body = process_request_body(body)

    full_headers =
      headers
      |> add_content_type_header
      |> add_shield_header
      |> add_custom_headers(method, full_url, body)

    options = Keyword.merge(default_httpoison_options(), options)
    {m, f, _a} = Elastix.config(:test_request_mfa) || {HTTPoison.Base, :request, []}

    request = %HTTPoison.Request{
      method: method,
      url: full_url,
      headers: process_request_headers(full_headers),
      body: process_request_body(body),
      options: options
    }

    apply(m, f, [
      __MODULE__,
      request,
      &process_response_status_code/1,
      &process_response_headers/1,
      &process_response_body/1,
      &process_response/1
    ])
  end

  @doc false
  def process_response_body(""), do: ""

  def process_response_body(body) do
    case body |> to_string |> JSON.decode() do
      {:error, _} -> body
      {:ok, decoded} -> decoded
    end
  end

  @doc """
  Encodes an enumerable (`params`) into a query string and appends it to `root`.

  ## Examples

      iex> Elastix.HTTP.append_query_string("/path", %{a: 1, b: 2})
      "/path?a=1&b=2"
  """
  @spec append_query_string(String.t(), term()) :: String.t()
  def append_query_string(root, params), do: "#{root}?#{URI.encode_query(params)}"

  defp default_httpoison_options do
    Elastix.config(:httpoison_options, [])
  end

  defp add_content_type_header(headers) do
    [{"Content-Type", "application/json; charset=UTF-8"} | headers]
  end

  defp add_shield_header(headers) do
    if Elastix.config(:shield) do
      username = Elastix.config(:username)
      password = Elastix.config(:password)
      encoded = Base.encode64("#{username}:#{password}")
      Keyword.put(headers, :Authorization, "Basic " <> encoded)
    else
      headers
    end
  end

  defp add_custom_headers(headers, method, url, body) do
    case Elastix.config(:custom_headers) do
      nil ->
        headers

      {mod, fun, args} ->
        request = %{method: method, headers: headers, url: url, body: body}

        case apply(mod, fun, [request | args]) do
          headers when is_list(headers) -> headers
          _ -> raise("custom headers must return a header list (keyword list)")
        end

      _ ->
        raise("Custom headers accepts a tuple of `{Module, :fun, []}` only.")
    end
  end
end

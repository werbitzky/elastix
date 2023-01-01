defmodule Elastix.HTTP do
  @moduledoc """
  A thin wrapper on [HTTPoison](https://github.com/edgurgel/httpoison).
  """
  use HTTPoison.Base
  alias Elastix.JSON

  @type resp :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}

  @doc "Create URL from base URL, path components and query params."
  @spec make_url(binary, binary | [binary], Enum.t) :: binary
  def make_url(url, path, query_params \\ [])
  def make_url(url, path, query_params) when is_list(path) do
    make_url(url, Path.join(path), query_params)
  end
  def make_url(url, path, query_params) do
    URI.merge(url, add_query_params(path, query_params)) |> to_string
  end

  @doc false
  def request(method, url, body \\ "", headers \\ [], options \\ []) do
    query_url = add_query_params(url, options[:params])
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
  @spec process_response_body(binary) :: term
  def process_response_body(""), do: ""
  def process_response_body(body) when is_binary(body) do
    case JSON.decode(body) do
      {:error, _} ->
        body
      {:ok, decoded} ->
        decoded
    end
  end
  def process_response_body(body) do
    process_response_body(to_string(body))
  end

  @doc """
  Add query parameters to end of path.

  ## Examples

      iex> Elastix.HTTP.add_query_params("/path", a: 1, b: 2)
      "/path?a=1&b=2"

      iex> Elastix.HTTP.add_query_params("/path", %{a: 1, b: 2})
      "/path?a=1&b=2"

  """
  @spec add_query_params(binary, Enum.t | nil) :: binary
  def add_query_params(url, params)
  def add_query_params(url, nil), do: url
  def add_query_params(url, []), do: url
  def add_query_params(url, map) when is_map(map) and map_size(map) == 0, do: url
  def add_query_params(url, params), do: url <> "?" <> URI.encode_query(params)

  defp default_httpoison_options do
    Elastix.config(:httpoison_options, [])
  end

  @doc false
  @spec add_content_type_header([{binary, binary}]) :: [{binary, binary}]
  def add_content_type_header(headers) do
    if :proplists.is_defined("Content-Type", headers) do
      headers
    else
      [{"Content-Type", "application/json; charset=UTF-8"} | headers]
    end
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

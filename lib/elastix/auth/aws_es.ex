defmodule Elastix.Auth.AWSES do
  @moduledoc """
  Include signed authorization header for AWS ElasticSearch.
  https://github.com/bryanjos/aws_auth
  """

  alias AWSAuth.Utils

  def process_headers(headers, {_, url, body} = request_data) do
    # cache current time for x-amz-date header and signing auth header
    datetime = current_time()

    headers
    |> put_host_header(url)
    |> put_amz_date_header(datetime)
    |> put_amz_content_sha_256_header(body)
    |> put_signed_request_header(request_data, datetime)
  end

  defp put_signed_request_header(headers, {method, url, body}, datetime) do
    configs = Elastix.config(:aws_es)
    method  = method |> Atom.to_string() |> String.upcase()

    # the aws_auth library requires headers as a map (vs. keyword list used by HTTPoison)
    auth_headers = headers_to_map(headers)

    signed_request = AWSAuth.sign_authorization_header(
      configs[:access_key],
      configs[:secret_key],
      method,
      url,
      configs[:region],
      "es",
      auth_headers,
      body,
      datetime
    )

    Keyword.put(headers, :"Authorization", signed_request)
  end

  defp put_host_header(headers, url) do
    host = URI.parse(url).host
    Keyword.put(headers, :"host", host)
  end

  defp put_amz_date_header(headers, datetime) do
    Keyword.put(headers, :"x-amz-date", Utils.format_time(datetime))
  end

  defp put_amz_content_sha_256_header(headers, body) do
    Keyword.put(headers, :"x-amz-content-sha256", Utils.hash_sha256(body))
  end

  defp current_time do
    DateTime.utc_now()
    |> DateTime.to_naive()
  end

  defp headers_to_map(headers) do
    headers
    |> Enum.map(fn {k,v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end
end

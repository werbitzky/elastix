defmodule Elastix.Auth.AWSES do
	@moduledoc """
	Include signed authorization header for AWS ElasticSearch.
	https://github.com/bryanjos/aws_auth
	"""

	def process_headers(headers, request_data) do
		# cache current time for x-amz-date header and signing auth header
		datetime = current_time()

		headers
		|> put_amz_date_header(datetime)
		|> put_signed_request_header(request_data, datetime)
  end

  defp put_signed_request_header(headers, {method, url, body}, datetime) do
  	configs      = Elastix.config(:aws_es)
    method       = method |> Atom.to_string() |> String.upcase()
    auth_headers = Enum.map(headers, fn {k,v} -> {Atom.to_string(k), v} end) |> Enum.into(%{})

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

  defp put_amz_date_header(headers, datetime) do
  	Keyword.put(headers, :"x-amz-date", AWSAuth.Utils.format_time(datetime))
  end

  defp current_time do
  	DateTime.utc_now() 
  	|> DateTime.to_naive()
  end
end
defmodule Elastix.Auth.AWSES do
	@moduledoc """
	Include signed authorization header for AWS ElasticSearch.
	https://github.com/bryanjos/aws_auth
	"""

	def process_headers(headers, request_data) do
		signed_request = sign_aws_authorization_header(request_data)

    Keyword.put(headers, :"Authorization", signed_request)
	end

  defp sign_aws_authorization_header({method, url, body}) do
    configs = Elastix.config(:aws_es)
    method  = method |> Atom.to_string() |> String.upcase()

    AWSAuth.sign_authorization_header(
      configs[:access_key], 
      configs[:secret_key], 
      method, 
      url, 
      configs[:region], 
      "es", 
      Map.new, 
      body
    )
  end
end
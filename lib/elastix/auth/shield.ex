defmodule Elastix.Auth.Shield do
  @moduledoc """
  Include Authorization header for Elastic Shield.
  https://www.elastic.co/guide/en/shield/current/_using_elasticsearch_http_rest_clients_with_shield.html
  """

  def process_headers(headers, _) do
    Keyword.put(headers, :"Authorization", auth_token())
  end

  defp auth_token do
    "Basic " <> Base.encode64("#{Elastix.config(:username)}:#{Elastix.config(:password)}")
  end
end

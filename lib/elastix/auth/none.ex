defmodule Elastix.Auth.None do
  @moduledoc """
  Bypass injecting Authorization header for requests without auth.
  """

  def process_headers(headers, _), do: headers
end

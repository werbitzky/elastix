defmodule Elastix.Alias do
  @moduledoc """
  The alias API adds or removes index aliases, a secondary name used to refer
  to one or more existing indices.

  [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html)
  """
  alias Elastix.{HTTP, JSON}

  @doc """
  Perform actions on aliases.

  Specify the list of actions in the `actions` parameter.

  ## Examples

      iex> actions = [%{add: %{index: "test1", alias: "alias1"}}]
      iex> Elastix.Alias.post("http://localhost:9200", actions)
      {:ok, %HTTPoison.Response{...}}

  """
  @spec post(binary, [map]) :: HTTP.resp
  def post(elastic_url, actions) do
    url = HTTP.make_url(elastic_url, "_aliases")
    HTTP.post(url, JSON.encode!(%{actions: actions}))
  end

  @doc """
  Returns information about one or more index aliases.

  ## Examples
      iex> Elastix.Alias.get("http://localhost:9200", "alias1")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec get(elastic_url :: String.t(), name :: String.t()) :: HTTP.resp()
  def get(elastic_url, name \\ "") do
    prepare_url(elastic_url, ["_alias", name])
    |> HTTP.get()
  end
end

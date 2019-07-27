defmodule Elastix.Alias do
  @moduledoc """
  The alias API makes it possible to perform alias operations on indexes.

  [Aliases documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html)
  """
  import Elastix.HTTP, only: [prepare_url: 2]
  alias Elastix.{HTTP, JSON}

  @doc """
  Excepts a list of actions for the `actions` parameter.

  ## Examples
      iex> actions = [%{ add: %{ index: "test1", alias: "alias1" }}]
      iex> Elastix.Alias.post("http://localhost:9200", actions)
      {:ok, %HTTPoison.Response{...}}
  """
  @spec post(elastic_url :: String.t(), actions :: list) :: HTTP.resp()
  def post(elastic_url, actions) do
    prepare_url(elastic_url, ["_aliases"])
    |> HTTP.post(JSON.encode!(%{actions: actions}))
  end
end

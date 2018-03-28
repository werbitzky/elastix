defmodule Elastix.Snapshot.Repository do
  @moduledoc """
  Functions for working with repositories. A repository is required for taking and restoring snapshots of indices.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html)
  """

  import Elastix.HTTP, only: [prepare_url: 2]
  alias Elastix.{HTTP, JSON}

  @doc """
  Registers a repository.
  """
  @spec register(String.t(), String.t(), Map.t(), [tuple()]) ::
          {:ok, %HTTPoison.Response{}}
  def register(elastic_url, repo_name, data, query_params \\ []) do
    elastic_url
    |> prepare_url(make_path(repo_name, query_params))
    |> HTTP.put(JSON.encode!(data))
  end

  @doc """
  Verifies a registered but unverified repository.
  """
  @spec verify(String.t(), String.t()) :: {:ok, %HTTPoison.Response{}}
  def verify(elastic_url, repo_name) do
    elastic_url
    |> prepare_url([make_path(repo_name), "_verify"])
    |> HTTP.post("")
  end

  @doc """
  If repo_name specified, will retrieve information about a registered repository.
  Otherwise, will retrieve information about all repositories.
  """
  @spec get(String.t(), String.t()) :: {:ok, %HTTPoison.Response{}}
  def get(elastic_url, repo_name \\ "_all") do
    elastic_url
    |> prepare_url(make_path(repo_name))
    |> HTTP.get()
  end

  @doc """
  Removes the reference to the location where the snapshots are stored.
  """
  @spec delete(String.t(), String.t()) :: {:ok, %HTTPoison.Response{}}
  def delete(elastic_url, repo_name) do
    elastic_url
    |> prepare_url(make_path(repo_name))
    |> HTTP.delete()
  end

  @doc false
  @spec make_path(String.t(), [tuple()]) :: String.t()
  def make_path(repo_name, query_params \\ []) do
    path = _make_base_path(repo_name)

    case query_params do
      [] -> path
      _ -> _add_query_params(path, query_params)
    end
  end

  defp _make_base_path(nil), do: "/_snapshot"
  defp _make_base_path(repo_name), do: "/_snapshot/#{repo_name}"

  defp _add_query_params(path, query_params) do
    query_string =
      query_params
      |> Enum.map_join("&", fn param ->
        "#{elem(param, 0)}=#{elem(param, 1)}"
      end)

    "#{path}?#{query_string}"
  end
end

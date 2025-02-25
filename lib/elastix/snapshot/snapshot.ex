defmodule Elastix.Snapshot.Snapshot do
  @moduledoc """
  Functions for working with snapshots.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html)
  """

  import Elastix.HTTP, only: [prepare_url: 2]

  alias Elastix.HTTP
  alias Elastix.JSON

  @doc """
  Creates a snapshot.
  """
  @spec create(String.t(), String.t(), String.t(), Map.t(), [tuple()], Keyword.t()) ::
          {:ok, HTTPoison.Response.t()}
  def create(elastic_url, repo_name, snapshot_name, data \\ %{}, query_params \\ [], options \\ []) do
    elastic_url
    |> prepare_url(make_path(repo_name, snapshot_name, query_params))
    |> HTTP.put(JSON.encode!(data), [], _make_httpoison_options(options))
  end

  @doc """
  Restores a previously created snapshot.
  """
  @spec restore(String.t(), String.t(), String.t(), Map.t(), Keyword.t()) ::
          {:ok, HTTPoison.Response.t()}
  def restore(elastic_url, repo_name, snapshot_name, data \\ %{}, options \\ []) do
    elastic_url
    |> prepare_url([make_path(repo_name, snapshot_name), "_restore"])
    |> HTTP.post(JSON.encode!(data), [], _make_httpoison_options(options))
  end

  @doc """
  If repo_name and snapshot_name is specified, will retrieve the status of that
  snapsot. If repo_name is specified, will retrieve the status of all snapshots
  in that repository. Otherwise, will retrieve the status of all snapshots.
  """
  @spec status(String.t(), String.t(), String.t(), Keyword.t()) ::
          {:ok, HTTPoison.Response.t()}
  def status(elastic_url, repo_name \\ "", snapshot_name \\ "", options \\ []) do
    elastic_url
    |> prepare_url([make_path(repo_name, snapshot_name), "_status"])
    |> HTTP.get([], _make_httpoison_options(options))
  end

  @doc """
  If repo_name and snapshot_name is specified, will retrieve information about
  that snapshot. If repo_name is specified, will retrieve information about
  all snapshots in that repository. Otherwise, will retrieve information about
  all snapshots.
  """
  @spec get(String.t(), String.t(), String.t(), Keyword.t()) ::
          {:ok, HTTPoison.Response.t()}
  def get(elastic_url, repo_name \\ "", snapshot_name \\ "_all", options \\ []) do
    elastic_url
    |> prepare_url(make_path(repo_name, snapshot_name))
    |> HTTP.get([], _make_httpoison_options(options))
  end

  @doc """
  Deletes a snapshot from a repository.

  This can also be used to stop currently running snapshot and restore
  operations. Snapshot deletes can be slow, so you can pass in
  HTTPoison/Hackney options in an `httpoison_options` keyword argument like
  `:recv_timeout` to wait longer.

  ## Examples

      iex> Elastix.Snapshot.Snapshot.delete("http://localhost:9200", "backups", "snapshot_123", httpoison_options: [recv_timeout: 30_000])
      {:ok, %HTTPoison.Response{...}}

  """
  @spec delete(String.t(), String.t(), String.t(), Keyword.t()) :: {:ok, HTTPoison.Response.t()}
  def delete(elastic_url, repo_name, snapshot_name, options \\ []) do
    elastic_url
    |> prepare_url(make_path(repo_name, snapshot_name))
    |> HTTP.delete([], _make_httpoison_options(options))
  end

  @doc false
  @spec make_path(String.t(), [tuple()]) :: String.t()
  def make_path(repo_name, snapshot_name, query_params \\ []) do
    path = _make_base_path(repo_name, snapshot_name)

    case query_params do
      [] -> path
      _ -> _add_query_params(path, query_params)
    end
  end

  defp _make_httpoison_options(options), do: Keyword.get(options, :httpoison_options, [])

  defp _make_base_path(nil, nil), do: "/_snapshot"
  defp _make_base_path(repo_name, nil), do: "/_snapshot/#{repo_name}"

  defp _make_base_path(repo_name, snapshot_name), do: "/_snapshot/#{repo_name}/#{snapshot_name}"

  defp _add_query_params(path, query_params) do
    query_string =
      Enum.map_join(query_params, "&", fn param ->
        "#{elem(param, 0)}=#{elem(param, 1)}"
      end)

    "#{path}?#{query_string}"
  end
end

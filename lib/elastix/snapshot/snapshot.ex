defmodule Elastix.Snapshot.Snapshot do
  @moduledoc """
  Functions for working with snapshots.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html)
  """

  alias Elastix.{HTTP, JSON}

  @doc """
  Create snapshot.

  [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html#snapshots-take-snapshot)

  ## Examples

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix_test_repository_1"
      iex> snapshot = "elastix_test_snapshot_2"
      iex> config = %{indices: "elastix_test_index_1,elastix_test_index_2"
      iex> Elastix.Snapshot.create(elastic_url, repository, snapshot, wait_for_completion: true)
      {:ok,
        %HTTPoison.Response{
          body: %{
            "snapshot" => %{
              "duration_in_millis" => 74,
              "end_time" => "2019-11-17T00:29:44.931Z",
              "end_time_in_millis" => 1573950584931,
              "failures" => [],
              "include_global_state" => true,
              "indices" => ["elastix_test_index_2", "elastix_test_index_1"],
              "shards" => %{"failed" => 0, "successful" => 10, "total" => 10},
              "snapshot" => "elastix_test_snapshot_2",
              "start_time" => "2019-11-17T00:29:44.857Z",
              "start_time_in_millis" => 1573950584857,
              "state" => "SUCCESS",
              "uuid" => "kBL1rleOQS-qfXqvXatNng",
              "version" => "6.8.4",
              "version_id" => 6080499
            }
          },
          headers: [{"content-type", "application/json; charset=UTF-8"}, {"content-length", "463"}],
          request: %HTTPoison.Request{
            body: "{\"indices\":\"elastix_test_index_1,elastix_test_index_2\"}",
            headers: [{"Content-Type", "application/json; charset=UTF-8"}],
            method: :put,
            options: [],
            params: %{},
            url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository/elastix_test_snapshot_2?wait_for_completion=true"
          },
          request_url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository/elastix_test_snapshot_2?wait_for_completion=true",
          status_code: 200
        }
      }

  """
  @spec create(binary, binary, binary, map, Keyword.t) :: HTTP.resp
  def create(elastic_url, repo, snapshot, config \\ %{}, query_params \\ []) do
    url = HTTP.make_url(elastic_url, make_path(repo, snapshot), query_params)
    HTTP.put(url, JSON.encode!(config))
  end

  @doc """
  Restore previously created snapshot.
  """
  @spec restore(binary, binary, binary, map) :: HTTP.resp
  def restore(elastic_url, repo, snapshot, data \\ %{}) do
    url = HTTP.make_url(elastic_url, [make_path(repo, snapshot), "_restore"])
    HTTP.post(url, JSON.encode!(data))
  end

  @doc """
  Get status of snapshots.

  If repo and snapshot is specified, will retrieve the status of that
  snapshot. If repo is specified, will retrieve the status of all snapshots
  in that repository. Otherwise, will retrieve the status of all snapshots.

  ## Examples

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix_test_repository_1"
      iex> snapshot = "elastix_test_snapshot_2"
      iex> Elastix.Snapshot.status(elastic_url, repository, snapshot)

  """
  @spec status(binary, binary, binary) :: HTTP.resp
  def status(elastic_url, repo \\ "", snapshot \\ "") do
    url = HTTP.make_url(elastic_url, [make_path(repo, snapshot), "_status"])
    HTTP.get(url)
  end

  @doc """
  Get information about snapshot.

  If repo_name and snapshot_name is specified, will retrieve information about
  that snapshot. If repo_name is specified, will retrieve information about
  all snapshots in that repository. Oterwise, will retrieve information about
  all snapshots.

  ## Examples

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix_test_repository_1"
      iex> snapshot = "elastix_test_snapshot_2"
      iex> Elastix.Snapshot.get(elastic_url, repository, snapshot)
      {:ok,
        %HTTPoison.Response{
          body: %{
            "snapshots" => [
              %{
                "duration_in_millis" => 45,
                "end_time" => "2019-11-17T00:37:03.858Z",
                "end_time_in_millis" => 1573951023858,
                "failures" => [],
                "include_global_state" => true,
                "indices" => ["elastix_test_index_2", "elastix_test_index_1"],
                "shards" => %{"failed" => 0, "successful" => 10, "total" => 10},
                "snapshot" => "elastix_test_snapshot_2",
                "start_time" => "2019-11-17T00:37:03.813Z",
                "start_time_in_millis" => 1573951023813,
                "state" => "SUCCESS",
                "uuid" => "_l_J5caMQkWVx16kLhwoaw",
                "version" => "6.8.4",
                "version_id" => 6080499
              }
            ]
          },
          headers: [{"content-type", "application/json; charset=UTF-8"}, {"content-length", "466"}],
          request: %HTTPoison.Request{
            body: "",
            headers: [{"Content-Type", "application/json; charset=UTF-8"}],
            method: :get,
            options: [],
            params: %{},
            url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository/elastix_test_snapshot_2"
          },
          request_url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository/elastix_test_snapshot_2",
          status_code: 200
        }
      }

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix_test_repository_1"
      iex> Elastix.Snapshot.get(elastic_url, repository)

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix_test_repository_1"
      iex> Elastix.Snapshot.get(elastic_url)

  """
  @spec get(binary, binary, binary) :: HTTP.resp
  def get(elastic_url, repo_name \\ "", snapshot_name \\ "_all") do
    url = HTTP.make_url(elastic_url, make_path(repo_name, snapshot_name))
    HTTP.get(url)
  end

  @doc """
  Delete snapshot from repository.

  This can also be used to stop currently running snapshot and restore operations.
  """
  @spec delete(binary, binary, binary) :: HTTP.resp
  def delete(elastic_url, repo, snapshot) do
    url = HTTP.make_url(elastic_url, make_path(repo, snapshot))
    HTTP.delete(url)
  end

 @doc false
  @spec make_path(binary | nil, binary | nil) :: binary
  def make_path(repo, snapshot)
  def make_path(nil, nil), do: "/_snapshot"
  def make_path(repo, nil), do: "/_snapshot/#{repo}"
  def make_path(repo, snapshot), do: "/_snapshot/#{repo}/#{snapshot}"

end

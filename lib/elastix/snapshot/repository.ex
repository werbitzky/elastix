defmodule Elastix.Snapshot.Repository do
  @moduledoc """
  Functions for working with repositories.

  A repository is a location used to store snapshots when
  backing up and restoring data in an Elasticsearch cluster.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html)
  """

  alias Elastix.{HTTP, JSON}

  @doc """
  Register repository.

  It's necessary to register a snapshot repository before performing
  snapshot and restore operations.

  ## Examples

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix_test_repository_1"
      iex> config = %{type: "fs", settings: %{location: "/tmp/elastix/backups"}}
      iex> Elastix.Repository.register(elastic_url, repository, config)
      {:ok,
        %HTTPoison.Response{
          body: %{"acknowledged" => true},
          headers: [{"content-type", "application/json; charset=UTF-8"}, {"content-length", "21"}],
          request: %HTTPoison.Request{
            body: "{\"type\":\"fs\",\"settings\":{\"location\":\"/tmp/elastix/backups\"}}",
            headers: [{"Content-Type", "application/json; charset=UTF-8"}],
            method: :put,
            options: [],
            params: %{},
            url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository_1"
          },
          request_url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository_1",
          status_code: 200
        }
      }

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix_test_repository_2"
      iex> config = %{type: "fs", settings: %{location: "/tmp/elastix/backups"}}
      iex> Elastix.Repository.register(elastic_url, repository, config, verify: false)
      {:ok,
        %HTTPoison.Response{
          body: %{"acknowledged" => true},
          headers: [{"content-type", "application/json; charset=UTF-8"}, {"content-length", "21"}],
          request: %HTTPoison.Request{
            body: "{\"type\":\"fs\",\"settings\":{\"location\":\"/tmp/elastix/backups\"}}",
            headers: [{"Content-Type", "application/json; charset=UTF-8"}],
            method: :put,
            options: [],
            params: %{},
            url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository_2?verify=false"
          },
          request_url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository_2?verify=false",
          status_code: 200
        }
      }

  """
  @spec register(binary, binary, map, Keyword.t) :: HTTP.resp
  def register(elastic_url, repo, config, query_params \\ []) do
    url = HTTP.make_url(elastic_url, make_path(repo), query_params)
    HTTP.put(url, JSON.encode!(config))
  end

  @doc """
  Verify repository.

  Verify a repository which was initially registered without verification,
  (`verify: false`).

  Returns list of nodes where repository was successfully verified or an error
  message if verification failed.

  [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html#_repository_verification)

  ## Examples

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix_test_repository"
      iex> Elastix.Repository.verify(elastic_url, repository)
      {:ok,
        %HTTPoison.Response{
          body: %{"nodes" => %{"O5twn2YcS0GvFPra5lllUQ" => %{"name" => "O5twn2Y"}}},
          headers: [{"content-type", "application/json; charset=UTF-8"}, {"content-length", "55"}],
          request: %HTTPoison.Request{
            body: "",
            headers: [{"Content-Type", "application/json; charset=UTF-8"}],
            method: :post,
            options: [],
            params: %{},
            url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository_2/_verify"
          },
          request_url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository_2/_verify",
          status_code: 200
        }
      }

  """
  @spec verify(binary, binary) :: HTTP.resp
  def verify(elastic_url, repo) do
    url = HTTP.make_url(elastic_url, [make_path(repo), "_verify"])
    HTTP.post(url, "")
  end

  @doc """
  Get info about repositories.

  Gets info about all repositories, or a single repo if specified.

  ## Examples

      iex> elastic_url = "http://localhost:9200"
      iex> Elastix.Repository.get(elastic_url)
      {:ok,
        %HTTPoison.Response{
          body: %{
            "elastix_test_repository_1" => %{"settings" => %{"location" => "/tmp/elastix/backups"}, "type" => "fs"},
            "elastix_test_repository_2" => %{"settings" => %{"location" => "/tmp/elastix/backups"}, "type" => "fs"}
          },
          headers: [{"content-type", "application/json; charset=UTF-8"}, {"content-length", "179"}],
          request: %HTTPoison.Request{
            body: "",
            headers: [{"Content-Type", "application/json; charset=UTF-8"}],
            method: :get,
            options: [],
            params: %{},
            url: "http://127.0.0.1:9200/_snapshot/_all"
          },
          request_url: "http://127.0.0.1:9200/_snapshot/_all",
          status_code: 200
        }
      }

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix_test_repository_1"
      iex> Elastix.Repository.get(elastic_url, repository)
      {:ok,
        %HTTPoison.Response{
          body: %{"elastix_test_repository_1" => %{"settings" => %{"location" => "/tmp/elastix/backups"}, "type" => "fs"}},
          headers: [{"content-type", "application/json; charset=UTF-8"}, {"content-length", "90"}],
          request: %HTTPoison.Request{
            body: "",
            headers: [{"Content-Type", "application/json; charset=UTF-8"}],
            method: :get,
            options: [],
            params: %{},
            url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository_1"
          },
          request_url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository_1",
          status_code: 200
        }
      }

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix*"
      iex> Elastix.Repository.get(elastic_url, repository)

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "foo,bar"
      iex> Elastix.Repository.get(elastic_url, repository)

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "nonexistent"
      iex> Elastix.Repository.get(elastic_url, repository)
      {:ok,
        %HTTPoison.Response{
          body: %{
            "error" => %{
              "reason" => "[nonexistent] missing",
              "root_cause" => [%{"reason" => "[nonexistent] missing", "type" => "repository_missing_exception"}],
              "type" => "repository_missing_exception"
            },
            "status" => 404
          },
          headers: [{"content-type", "application/json; charset=UTF-8"}, {"content-length", "183"}],
          request: %HTTPoison.Request{
            body: "",
            headers: [{"Content-Type", "application/json; charset=UTF-8"}],
            method: :get,
            options: [],
            params: %{},
            url: "http://127.0.0.1:9200/_snapshot/nonexistent"
          },
          request_url: "http://127.0.0.1:9200/_snapshot/nonexistent",
          status_code: 404
        }
      }


  """
  @spec get(binary, binary) :: HTTP.resp
  def get(elastic_url, repo \\ "_all") do
    url = HTTP.make_url(elastic_url, make_path(repo))
    HTTP.get(url)
  end


  @doc """
  Remove reference to location where snapshots are stored.

  ## Examples

      iex> elastic_url = "http://localhost:9200"
      iex> repository = "elastix_test_repository_1"
      iex> Elastix.Repository.get(elastic_url, repository)
      {:ok,
        %HTTPoison.Response{
          body: %{"acknowledged" => true},
          headers: [{"content-type", "application/json; charset=UTF-8"}, {"content-length", "21"}],
          request: %HTTPoison.Request{
            body: "",
            headers: [{"Content-Type", "application/json; charset=UTF-8"}],
            method: :delete,
            options: [],
            params: %{},
            url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository_1"
          },
          request_url: "http://127.0.0.1:9200/_snapshot/elastix_test_repository_1",
          status_code: 200
        }
      }

  """
  @spec delete(binary, binary) :: HTTP.resp
  def delete(elastic_url, repo) do
    url = HTTP.make_url(elastic_url, make_path(repo))
    HTTP.delete(url)
  end

  @doc """
  Clean up unreferenced data in a repository.

  Trigger a complete accounting of the repositories contents and subsequent
  deletion of all unreferenced data that was found.

  Deleting a snapshot performs this cleanup.

  Available in Elasticsearch 7.x and later.
  """
  @spec cleanup(binary, binary) :: HTTP.resp
  def cleanup(elastic_url, repo) do
    url = HTTP.make_url(elastic_url, [make_path(repo), "_cleanup"])
    HTTP.post(url, "")
  end

  @doc false
  # Make path from arguments
  @spec make_path(binary | nil) :: binary
  def make_path(nil), do: "/_snapshot"
  def make_path(repo), do: "/_snapshot/#{repo}"

end

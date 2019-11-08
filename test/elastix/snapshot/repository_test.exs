defmodule Elastix.Snapshot.RepositoryTest do
  @moduledoc """
  Tests for the Elastix.Snapshot.Repository module functions.

  Note that for these tests to run, Elasticsearch must be running and the
  config file `elasticsearch.yml` file must have the following entry:

  `path.repo: ["/tmp/elastix/backups"]`

  [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html#_shared_file_system_repository)
  """

  use ExUnit.Case
  alias Elastix.Snapshot.Repository
  alias Elastix.HTTP

  @test_url Elastix.config(:test_url)
  @repo_config %{"type" => "fs", "settings" => %{"location" => "/tmp/elastix/backups"}}
  @repo_1 "elastix_test_repository_1"
  @repo_2 "elastix_test_repository_2"

  setup_all do
    # Query the Elasticsearch instance to determine what version it is running
    # so we can use it in tests.
    {:ok, response} = HTTP.get(@test_url)
    version_string = response.body["version"]["number"]
    version = Elastix.version_to_tuple(version_string)

    {:ok, version: version}
  end

  setup do
    on_exit(fn ->
      Repository.delete(@test_url, @repo_1)
      Repository.delete(@test_url, @repo_2)
    end)

    :ok
  end

  describe "make_path/2" do
    test "handles all parameter variations" do
      assert Repository.make_path(nil) == "/_snapshot"
      assert Repository.make_path("foo") == "/_snapshot/foo"
    end
  end

  describe "registering a repository" do
    test "a repository" do
      {:ok, response} = Repository.register(@test_url, @repo_1, @repo_config)
      assert response.status_code == 200
    end
  end

  describe "verifying a repository" do
    test "a registered but unverified repository is manually verified" do
      {:ok, response} = Repository.register(@test_url, @repo_2, @repo_config, verify: false)
      assert response.status_code == 200

      {:ok, response} = Repository.verify(@test_url, @repo_2)
      assert response.status_code == 200
      assert response.body["nodes"] != ""
    end
  end

  describe "retrieving information about a repository" do
    test "repository doesn't exist" do
      {:ok, response} = Repository.get(@test_url, "nonexistent")
      assert response.status_code == 404
    end

    test "information about all repositories" do
      {:ok, %{status_code: 200}} = Repository.register(@test_url, @repo_1, @repo_config)
      {:ok, %{status_code: 200}} = Repository.register(@test_url, @repo_2, @repo_config)

      {:ok, response} = Repository.get(@test_url)
      assert response.status_code == 200
      assert response.body[@repo_1] == @repo_config
      assert response.body[@repo_2] == @repo_config
    end

    test "information about a specific repository" do
      Repository.register(@test_url, @repo_1, @repo_config)
      {:ok, response} = Repository.get(@test_url, @repo_1)
      assert response.status_code == 200
      assert response.body[@repo_1] == @repo_config
    end
  end

  describe "cleanup" do
    test "repository", %{version: version} do
      if version >= {7, 0, 0} do
        {:ok, %{status_code: 200}} = Repository.register(@test_url, @repo_1, @repo_config)
        {:ok, response} = Repository.cleanup(@test_url, @repo_1)
        assert response.status_code == 200
      end
    end
  end

  describe "deleting a repository" do
    test "repository doesn't exist" do
      assert {:ok, %{status_code: 404}} = Repository.delete(@test_url, "nonexistent")
    end

    test "references to the location where snapshots are stored are removed" do
      assert {:ok, %{status_code: 200}} = Repository.register(@test_url, @repo_1, @repo_config)

      assert {:ok, %{status_code: 200}} = Repository.delete(@test_url, @repo_1)
      assert {:ok, %{status_code: 404}} = Repository.get(@test_url, @repo_1)
    end
  end
end

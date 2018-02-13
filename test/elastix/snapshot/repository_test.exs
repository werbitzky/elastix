defmodule Elastix.Snapshot.RepositoryTest do
  @moduledoc """
  Tests for the Elastix.Snapshot.Repository module functions.

  Note that for these tests to run, Elasticsearch must be running and the
  elasticsearch.yml file must have the following entry:

    path.repo: /tmp
  """

  use ExUnit.Case
  alias Elastix.Snapshot.Repository

  @test_url Elastix.config(:test_url)
  @test_repository_config %{type: "fs", settings: %{location: "/tmp"}}

  setup do
    on_exit(fn ->
      Repository.delete(@test_url, "elastix_test_repository_1")
      Repository.delete(@test_url, "elastix_test_repository_2")
    end)

    :ok
  end

  describe "constructing paths" do
    test "make_path should make url from repository name and query params" do
      assert Repository.make_path("elastix_test_unverified_backup", verify: false) ==
               "/_snapshot/elastix_test_unverified_backup?verify=false"
    end

    test "make_path should make url from repository_name" do
      assert Repository.make_path("elastix_test_repository_1") ==
               "/_snapshot/elastix_test_repository_1"
    end
  end

  describe "registering a repository" do
    test "a repository" do
      assert {:ok, %{status_code: 200}} =
               Repository.register(
                 @test_url,
                 "elastix_test_repository_1",
                 @test_repository_config
               )
    end

    test "an unverified repository" do
      assert {:ok, %{status_code: 200}} =
               Repository.register(
                 @test_url,
                 "elastix_test_repository_1",
                 @test_repository_config,
                 verify: false
               )
    end
  end

  describe "verifying a repository" do
    test "a registered but unverified repository is manually verified" do
      Repository.register(
        @test_url,
        "elastix_test_repository_1",
        @test_repository_config,
        verify: false
      )

      assert {:ok, %{status_code: 200, body: %{"nodes" => _}}} =
               Repository.verify(@test_url, "elastix_test_repository_1")
    end
  end

  describe "retrieving information about a repository" do
    test "repository doesn't exist" do
      assert {:ok, %{status_code: 404}} = Repository.get(@test_url, "nonexistent")
    end

    test "information about all repositories" do
      Repository.register(@test_url, "elastix_test_repository_1", @test_repository_config)
      Repository.register(@test_url, "elastix_test_repository_2", @test_repository_config)

      assert {:ok, %{status_code: 200}} = Repository.get(@test_url)
    end

    test "information about a specific repository" do
      Repository.register(@test_url, "elastix_test_repository_1", @test_repository_config)

      assert {:ok, %{status_code: 200}} = Repository.get(@test_url, "elastix_test_repository_1")
    end
  end

  describe "deleting a repository" do
    test "repository doesn't exist" do
      assert {:ok, %{status_code: 404}} = Repository.delete(@test_url, "nonexistent")
    end

    test "references to the location where snapshots are stored are removed" do
      Repository.register(@test_url, "elastix_test_repository_1", @test_repository_config)

      assert {:ok, %{status_code: 200}} =
               Repository.delete(@test_url, "elastix_test_repository_1")

      assert {:ok, %{status_code: 404}} = Repository.get(@test_url, "elastix_test_repository_1")
    end
  end
end

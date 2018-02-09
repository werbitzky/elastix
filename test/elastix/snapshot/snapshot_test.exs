defmodule Elastix.Snapshot.SnapshotTest do
  @moduledoc """
  Tests for the Elastix.Snapshot.Snapshot module functions.

  Note that for these tests to run, Elasticsearch must be running and the
  elasticsearch.yml file must have the following entry:

    path.repo /tmp

  For testing purposes, snapshots are limited to test indices only.
  """

  use ExUnit.Case
  alias Elastix.Index
  alias Elastix.Snapshot.{Repository, Snapshot}

  @test_url Elastix.config(:test_url)
  @test_repository "elastix_test_repository"

  setup_all do
    Index.create(@test_url, "elastix_test_index_1", %{})
    Index.create(@test_url, "elastix_test_index_2", %{})

    Repository.register(@test_url, @test_repository, %{
      type: "fs",
      settings: %{
        location: "/tmp",
        max_snapshot_bytes_per_sec: "200mb",
        max_restore_bytes_per_sec: "200mb"
      }
    })

    :ok
  end

  setup do
    on_exit(fn ->
      Snapshot.delete(@test_url, @test_repository, "elastix_test_snapshot_1")
      Snapshot.delete(@test_url, @test_repository, "elastix_test_snapshot_2")
    end)

    :ok
  end

  describe "constructing paths" do
    test "make_path should make url from repository name, snapshot name, and query params" do
      assert Snapshot.make_path(
               @test_repository,
               "elastix_test_snapshot_1",
               wait_for_completion: true
             ) ==
               "/_snapshot/#{@test_repository}/elastix_test_snapshot_1?wait_for_completion=true"
    end

    test "make_path should make url from repository name and snapshot name" do
      assert Snapshot.make_path(@test_repository, "elastix_test_snapshot_1") ==
               "/_snapshot/#{@test_repository}/elastix_test_snapshot_1"
    end
  end

  describe "creating a snapshot" do
    test "a snapshot of multiple indices in the cluster" do
      assert {:ok, %{status_code: 200}} =
               Snapshot.create(
                 @test_url,
                 @test_repository,
                 "elastix_test_snapshot_1",
                 %{
                   indices: ["elastix_test_index_1", "elastix_test_index_2"]
                 },
                 wait_for_completion: true
               )

      Process.sleep(1000)

      assert {:ok, %{body: %{"snapshots" => snapshots}}} =
               Snapshot.get(@test_url, @test_repository, "elastix_test_snapshot_1")

      snapshot =
        Enum.find(snapshots, fn snapshot -> snapshot["snapshot"] == "elastix_test_snapshot_1" end)

      assert Enum.member?(snapshot["indices"], "elastix_test_index_1")
      assert Enum.member?(snapshot["indices"], "elastix_test_index_2")
    end

    test "a snapshot of a single index in the cluster" do
      assert {:ok, %{status_code: 200}} =
               Snapshot.create(
                 @test_url,
                 @test_repository,
                 "elastix_test_snapshot_1",
                 %{
                   indices: ["elastix_test_index_1"]
                 },
                 wait_for_completion: true
               )

      Process.sleep(1000)

      assert {:ok, %{body: %{"snapshots" => snapshots}}} =
               Snapshot.get(@test_url, @test_repository, "elastix_test_snapshot_1")

      snapshot =
        Enum.find(snapshots, fn snapshot -> snapshot["snapshot"] == "elastix_test_snapshot_1" end)

      assert Enum.member?(snapshot["indices"], "elastix_test_index_1")
      refute Enum.member?(snapshot["indices"], "elastix_test_index_2")
    end
  end

  describe "restoring a snapshot" do
    test "all indices in a snapshot" do
      assert {:ok, %{status_code: 200}} =
               Snapshot.create(
                 @test_url,
                 @test_repository,
                 "elastix_test_snapshot_1",
                 %{indices: ["elastix_test_index_1", "elastix_test_index_2"]},
                 wait_for_completion: true
               )

      Process.sleep(1000)

      Index.delete(@test_url, "elastix_test_index_1")
      Index.delete(@test_url, "elastix_test_index_2")

      assert {:ok, %{status_code: 200}} =
               Snapshot.restore(@test_url, @test_repository, "elastix_test_snapshot_1")

      assert {:ok, %{status_code: 200}} = Index.get(@test_url, "elastix_test_index_1")
      assert {:ok, %{status_code: 200}} = Index.get(@test_url, "elastix_test_index_2")
    end

    test "a specific index in a snapshot" do
      assert {:ok, %{status_code: 200}} =
               Snapshot.create(
                 @test_url,
                 @test_repository,
                 "elastix_test_snapshot_1",
                 %{indices: ["elastix_test_index_1", "elastix_test_index_2"]},
                 wait_for_completion: true
               )

      Process.sleep(1000)

      Index.delete(@test_url, "elastix_test_index_1")
      Index.delete(@test_url, "elastix_test_index_2")

      assert {:ok, %{status_code: 200}} =
               Snapshot.restore(@test_url, @test_repository, "elastix_test_snapshot_1", %{
                 indices: "elastix_test_index_1"
               })

      assert {:ok, %{status_code: 200}} = Index.get(@test_url, "elastix_test_index_1")
      assert {:ok, %{status_code: 404}} = Index.get(@test_url, "elastix_test_index_2")
    end
  end

  describe "retrieving status information for a snapshot" do
    test "snapshot doesn't exist" do
      assert {:ok, %{status_code: 404}} = Snapshot.get(@test_url, @test_repository, "nonexistent")
    end

    test "information about all snapshots" do
      assert {:ok, %{status_code: 200}} = Snapshot.get(@test_url)
    end

    test "information about all snapshots in a repository" do
      assert {:ok, %{status_code: 200}} = Snapshot.get(@test_url, @test_repository)
    end

    test "information about a specific snapshot" do
      Snapshot.create(@test_url, @test_repository, "elastix_test_snapshot_1")

      assert {:ok, %{status_code: 200}} =
               Snapshot.get(@test_url, @test_repository, "elastix_test_snapshot_1")
    end
  end

  describe "retrieving information about a snapshot" do
    test "snapshot doesn't exist" do
      assert {:ok, %{status_code: 404}} = Snapshot.get(@test_url, @test_repository, "nonexistent")
    end

    test "information about all snapshots" do
      Snapshot.create(@test_url, @test_repository, "elastix_test_snapshot_1")
      Snapshot.create(@test_url, @test_repository, "elastix_test_snapshot_2")

      assert {:ok, %{status_code: 200}} = Snapshot.get(@test_url, @test_repository)
    end

    test "information about a specific snapshot" do
      Snapshot.create(@test_url, @test_repository, "elastix_test_snapshot_1", %{
        indices: ["elastix_test_index_1", "elastix_test_index_2"]
      })

      assert {:ok, %{status_code: 200}} =
               Snapshot.get(@test_url, @test_repository, "elastix_test_snapshot_1")
    end
  end

  describe "deleting a snapshot" do
    test "snapshot doesn't exist" do
      assert {:ok, %{status_code: 404}} =
               Snapshot.delete(@test_url, @test_repository, "nonexistent")
    end

    test "snapshot is deleted" do
      Snapshot.create(@test_url, @test_repository, "elastix_test_snapshot_1", %{
        indices: ["elastix_test_index_1", "elastix_test_index_2"]
      })

      assert {:ok, %{status_code: 200}} =
               Snapshot.delete(@test_url, @test_repository, "elastix_test_snapshot_1")

      assert {:ok, %{status_code: 404}} =
               Snapshot.get(@test_url, @test_repository, "elastix_test_snapshot_1")
    end
  end
end

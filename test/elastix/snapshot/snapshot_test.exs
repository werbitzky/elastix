defmodule Elastix.Snapshot.SnapshotTest do
  @moduledoc """
  Tests for the Elastix.Snapshot.Snapshot module functions.

  Note that for these tests to run, Elasticsearch must be running and the
  elasticsearch.yml file must have the following entry:

    path.repo: /tmp

  For testing purposes, snapshots are limited to test indices only.
  """

  use ExUnit.Case
  use Retry
  alias Elastix.Index
  alias Elastix.Snapshot.{Repository, Snapshot}

  @test_url Elastix.config(:test_url)
  @test_repository "elastix_test_repository"

  setup_all do
    Index.create(@test_url, "elastix_test_index_1", %{})
    Index.create(@test_url, "elastix_test_index_2", %{})
    Index.create(@test_url, "elastix_test_index_3", %{})
    Index.create(@test_url, "elastix_test_index_4", %{})
    Index.create(@test_url, "elastix_test_index_5", %{})

    Repository.register(@test_url, @test_repository, %{
      type: "fs",
      settings: %{location: "/tmp"}
    })

    on_exit(fn ->
      Index.delete(@test_url, "elastix_test_index_1")
      Index.delete(@test_url, "elastix_test_index_2")
      Index.delete(@test_url, "elastix_test_index_3")
      Index.delete(@test_url, "elastix_test_index_4")
      Index.delete(@test_url, "elastix_test_index_5")

      Repository.delete(@test_url, @test_repository)
    end)

    :ok
  end

  setup do
    on_exit(fn ->
      Snapshot.delete(@test_url, @test_repository, "elastix_test_snapshot_1")
      Snapshot.delete(@test_url, @test_repository, "elastix_test_snapshot_2")
      Snapshot.delete(@test_url, @test_repository, "elastix_test_snapshot_3")
      Snapshot.delete(@test_url, @test_repository, "elastix_test_snapshot_4")
      Snapshot.delete(@test_url, @test_repository, "elastix_test_snapshot_5")
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
      Snapshot.create(
        @test_url,
        @test_repository,
        "elastix_test_snapshot_2",
        %{indices: "elastix_test_index_1,elastix_test_index_2"},
        wait_for_completion: true
      )

      wait linear_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{body: %{"snapshots" => snapshots}}} =
          Snapshot.status(@test_url, @test_repository, "elastix_test_snapshot_2")

        snapshot = List.first(snapshots)
        snapshot["state"] == "SUCCESS"
      after
        _ ->
          {:ok, %{body: %{"snapshots" => snapshots}}} =
            Snapshot.get(@test_url, @test_repository, "elastix_test_snapshot_2")

          snapshot = List.first(snapshots)
          assert Enum.member?(snapshot["indices"], "elastix_test_index_1")
          assert Enum.member?(snapshot["indices"], "elastix_test_index_2")
      end
    end

    test "a snapshot of a single index in the cluster" do
      Snapshot.create(
        @test_url,
        @test_repository,
        "elastix_test_snapshot_1",
        %{indices: "elastix_test_index_1"},
        wait_for_completion: true
      )

      wait linear_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{body: %{"snapshots" => snapshots}}} =
          Snapshot.status(@test_url, @test_repository, "elastix_test_snapshot_1")

        snapshot = List.first(snapshots)
        snapshot["state"] == "SUCCESS"
      after
        _ ->
          {:ok, %{body: %{"snapshots" => snapshots}}} =
            Snapshot.get(@test_url, @test_repository, "elastix_test_snapshot_1")

          snapshot = List.first(snapshots)
          assert Enum.member?(snapshot["indices"], "elastix_test_index_1")
          refute Enum.member?(snapshot["indices"], "elastix_test_index_2")
      end
    end
  end

  describe "restoring a snapshot" do
    test "all indices in a snapshot" do
      Snapshot.create(
        @test_url,
        @test_repository,
        "elastix_test_snapshot_4",
        %{indices: "elastix_test_index_1,elastix_test_index_2"},
        wait_for_completion: true
      )

      wait linear_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{body: %{"snapshots" => snapshots}}} =
          Snapshot.status(@test_url, @test_repository, "elastix_test_snapshot_4")

        snapshot = List.first(snapshots)
        snapshot["state"] == "SUCCESS"
      after
        _ ->
          Index.close(@test_url, "elastix_test_index_1")
          Index.close(@test_url, "elastix_test_index_2")
          Index.delete(@test_url, "elastix_test_index_1")
          Index.delete(@test_url, "elastix_test_index_2")
      end

      wait linear_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{status_code: 404}} = Index.get(@test_url, "elastix_test_index_1")
        {:ok, %{status_code: 404}} = Index.get(@test_url, "elastix_test_index_2")
      after
        _ ->
          Snapshot.restore(@test_url, @test_repository, "elastix_test_snapshot_4", %{
            partial: true
          })
      end

      wait linear_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{status_code: 200}} = Index.get(@test_url, "elastix_test_index_1")
        {:ok, %{status_code: 200}} = Index.get(@test_url, "elastix_test_index_2")
      end
    end

    test "a specific index in a snapshot" do
      Snapshot.create(
        @test_url,
        @test_repository,
        "elastix_test_snapshot_3",
        %{indices: "elastix_test_index_3,elastix_test_index_4"},
        wait_for_completion: true
      )

      wait linear_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{status_code: 200, body: %{"snapshots" => snapshots}}} =
          Snapshot.status(@test_url, @test_repository, "elastix_test_snapshot_3")

        snapshot = List.first(snapshots)
        snapshot["state"] == "SUCCESS"
      after
        _ ->
          Index.close(@test_url, "elastix_test_index_3")
          Index.close(@test_url, "elastix_test_index_4")
          Index.delete(@test_url, "elastix_test_index_3")
          Index.delete(@test_url, "elastix_test_index_4")
      end

      wait linear_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{status_code: 404}} = Index.get(@test_url, "elastix_test_index_3")
        {:ok, %{status_code: 404}} = Index.get(@test_url, "elastix_test_index_4")
      after
        _ ->
          Snapshot.restore(@test_url, @test_repository, "elastix_test_snapshot_3", %{
            indices: "elastix_test_index_3"
          })
      end

      wait linear_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{status_code: 200}} = Index.get(@test_url, "elastix_test_index_3")
        {:ok, %{status_code: 404}} = Index.get(@test_url, "elastix_test_index_4")
      end
    end
  end

  describe "retrieving status information for a snapshot" do
    test "snapshot doesn't exist" do
      assert {:ok, %{status_code: 404}} =
               Snapshot.status(@test_url, @test_repository, "nonexistent")
    end

    test "information about all snapshots" do
      assert {:ok, %{status_code: 200}} = Snapshot.status(@test_url)
    end

    test "information about all snapshots in a repository" do
      assert {:ok, %{status_code: 200}} = Snapshot.status(@test_url, @test_repository)
    end

    test "information about a specific snapshot" do
      Snapshot.create(@test_url, @test_repository, "elastix_test_snapshot_5", %{
        indices: "elastix_test_index_5"
      })

      wait linear_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{status_code: 200}} =
          Snapshot.status(@test_url, @test_repository, "elastix_test_snapshot_5")
      end
    end
  end

  describe "retrieving information about a snapshot" do
    test "snapshot doesn't exist" do
      assert {:ok, %{status_code: 404}} =
               Snapshot.get(@test_url, @test_repository, "nonexistent")
    end

    test "information about all snapshots" do
      assert {:ok, %{status_code: 200}} = Snapshot.get(@test_url, @test_repository)
    end

    test "information about a specific snapshot" do
      Snapshot.create(@test_url, @test_repository, "elastix_test_snapshot_5", %{
        indices: "elastix_test_index_5"
      })

      assert {:ok, %{status_code: 200}} =
               Snapshot.get(@test_url, @test_repository, "elastix_test_snapshot_5")
    end
  end

  describe "deleting a snapshot" do
    test "snapshot doesn't exist" do
      assert {:ok, %{status_code: 404}} =
               Snapshot.delete(@test_url, @test_repository, "nonexistent")
    end

    test "snapshot is deleted" do
      Snapshot.create(@test_url, @test_repository, "elastix_test_snapshot_5", %{
        indices: "elastix_test_index_5"
      })

      assert {:ok, %{status_code: 200}} =
               Snapshot.delete(@test_url, @test_repository, "elastix_test_snapshot_5")

      assert {:ok, %{status_code: 404}} =
               Snapshot.get(@test_url, @test_repository, "elastix_test_snapshot_5")
    end
  end
end

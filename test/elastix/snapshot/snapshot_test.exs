defmodule Elastix.Snapshot.SnapshotTest do
  @moduledoc """
  Tests for the Elastix.Snapshot.Snapshot module functions.

  Note that for these tests to run, Elasticsearch must be running and the
  config file `elasticsearch.yml` file must have the following entry:

  `path.repo: ["/tmp/elastix/backups"]`

  [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html#_shared_file_system_repository)

  For testing purposes, snapshots are limited to test indices only.
  """

  use ExUnit.Case
  use Retry
  alias Elastix.Index
  alias Elastix.Snapshot.{Repository, Snapshot}

  @test_url Elastix.config(:test_url)
  @repo "elastix_test_repository"
  @repo_config %{type: "fs", settings: %{location: "/tmp/elastix/backups"}}
  @index_1 "elastix_test_index_1"
  @index_2 "elastix_test_index_2"
  @index_3 "elastix_test_index_3"
  @index_4 "elastix_test_index_4"
  @index_5 "elastix_test_index_5"

  @snapshot_1 "elastix_test_snapshot_1"
  @snapshot_2 "elastix_test_snapshot_2"
  @snapshot_3 "elastix_test_snapshot_3"
  @snapshot_4 "elastix_test_snapshot_4"
  @snapshot_5 "elastix_test_snapshot_5"

  setup_all do
    Index.create(@test_url, @index_1, %{})
    Index.create(@test_url, @index_2, %{})
    Index.create(@test_url, @index_3, %{})
    Index.create(@test_url, @index_4, %{})
    Index.create(@test_url, @index_5, %{})

    Repository.register(@test_url, @repo, @repo_config)

    on_exit(fn ->
      Index.delete(@test_url, @index_1)
      Index.delete(@test_url, @index_2)
      Index.delete(@test_url, @index_3)
      Index.delete(@test_url, @index_4)
      Index.delete(@test_url, @index_5)

      Repository.delete(@test_url, @repo)
    end)

    :ok
  end

  setup do
    on_exit(fn ->
      Snapshot.delete(@test_url, @repo, @snapshot_1)
      Snapshot.delete(@test_url, @repo, @snapshot_2)
      Snapshot.delete(@test_url, @repo, @snapshot_3)
      Snapshot.delete(@test_url, @repo, @snapshot_4)
      Snapshot.delete(@test_url, @repo, @snapshot_5)
    end)

    :ok
  end

  describe "constructing paths" do
    test "make_path/2 makes path from repository name and snapshot name" do
      assert Snapshot.make_path(@repo, @snapshot_1) == "/_snapshot/#{@repo}/#{@snapshot_1}"
    end
  end

  describe "creating a snapshot" do
    test "a snapshot of multiple indices in the cluster" do
      {:ok, response} = Snapshot.create(@test_url, @repo, @snapshot_2,
        %{indices: "#{@index_1},#{@index_2}"}, wait_for_completion: true)
      assert response.status_code == 200

      wait lin_backoff(500, 1) |> expiry(5_000) do
        (
          {:ok, response} = Snapshot.status(@test_url, @repo, @snapshot_2)
          snapshot = List.first(response.body["snapshots"])
          snapshot["state"] == "SUCCESS"
        )

        then

        (
          {:ok, response} = Snapshot.get(@test_url, @repo, @snapshot_2)
          snapshot = List.first(response.body["snapshots"])
          assert Enum.member?(snapshot["indices"], @index_1)
          assert Enum.member?(snapshot["indices"], @index_2)
        )
      end
    end

    test "a snapshot of a single index in the cluster" do
      {:ok, response} = Snapshot.create(@test_url, @repo, @snapshot_1,
        %{indices: @index_1}, wait_for_completion: true)
      assert response.status_code == 200

      wait lin_backoff(500, 1) |> expiry(5_000) do
        (
          {:ok, response} = Snapshot.status(@test_url, @repo, @snapshot_1)
          snapshot = List.first(response.body["snapshots"])
          snapshot["state"] == "SUCCESS"
        )

        then

        (
          {:ok, response} = Snapshot.get(@test_url, @repo, @snapshot_1)
          snapshot = List.first(response.body["snapshots"])
          assert Enum.member?(snapshot["indices"], @index_1)
          refute Enum.member?(snapshot["indices"], @index_2)
        )
      end
    end
  end

  describe "restoring a snapshot" do
    test "all indices in a snapshot" do
      {:ok, response} = Snapshot.create(@test_url, @repo, @snapshot_4,
        %{indices: "#{@index_1},#{@index_2}"}, wait_for_completion: true)
      assert response.status_code == 200

      wait lin_backoff(500, 1) |> expiry(5_000) do
        (
          {:ok, response} = Snapshot.status(@test_url, @repo, @snapshot_4)
          snapshot = List.first(response.body["snapshots"])
          snapshot["state"] == "SUCCESS"
        )

        then

        (
          Index.close(@test_url, @index_1)
          Index.close(@test_url, @index_2)
          Index.delete(@test_url, @index_1)
          Index.delete(@test_url, @index_2)
        )
      end

      wait lin_backoff(500, 1) |> expiry(5_000) do
        (
          {:ok, %{status_code: 404}} = Index.get(@test_url, @index_1)
          {:ok, %{status_code: 404}} = Index.get(@test_url, @index_2)
        )

        then

        Snapshot.restore(@test_url, @repo, @snapshot_4, %{partial: true})
      end

      wait lin_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{status_code: 200}} = Index.get(@test_url, @index_1)
        {:ok, %{status_code: 200}} = Index.get(@test_url, @index_2)
      end
    end

    test "a specific index in a snapshot" do
      {:ok, response} = Snapshot.create(@test_url, @repo, @snapshot_3,
        %{indices: Enum.join([@index_3, @index_4], ",")}, wait_for_completion: true)
      assert response.status_code == 200

      wait lin_backoff(500, 1) |> expiry(5_000) do
        (
          {:ok, response} = Snapshot.status(@test_url, @repo, @snapshot_3)
          assert response.status_code == 200
          snapshots = response.body["snapshots"]

          snapshot = List.first(snapshots)
          snapshot["state"] == "SUCCESS"
        )

        then

        (
          Index.close(@test_url, @index_3)
          Index.close(@test_url, @index_4)
          Index.delete(@test_url, @index_3)
          Index.delete(@test_url, @index_4)
        )
      end

      wait lin_backoff(500, 1) |> expiry(5_000) do
        (
          {:ok, %{status_code: 404}} = Index.get(@test_url, @index_3)
          {:ok, %{status_code: 404}} = Index.get(@test_url, @index_4)
        )

        then

        Snapshot.restore(@test_url, @repo, @snapshot_3, %{indices: @index_3})
      end

      wait lin_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{status_code: 200}} = Index.get(@test_url, @index_3)
        {:ok, %{status_code: 404}} = Index.get(@test_url, @index_4)
      end
    end
  end

  describe "retrieving status information for a snapshot" do
    test "snapshot doesn't exist" do
      assert {:ok, %{status_code: 404}} = Snapshot.status(@test_url, @repo, "nonexistent")
    end

    test "information about all snapshots" do
      assert {:ok, %{status_code: 200}} = Snapshot.status(@test_url)
    end

    test "information about all snapshots in a repository" do
      assert {:ok, %{status_code: 200}} = Snapshot.status(@test_url, @repo)
    end

    test "information about a specific snapshot" do
      Snapshot.create(@test_url, @repo, @snapshot_5, %{indices: @index_5})

      wait lin_backoff(500, 1) |> expiry(5_000) do
        {:ok, %{status_code: 200}} = Snapshot.status(@test_url, @repo, @snapshot_5)
      end
    end
  end

  describe "retrieving information about a snapshot" do
    test "snapshot doesn't exist" do
      assert {:ok, %{status_code: 404}} = Snapshot.get(@test_url, @repo, "nonexistent")
    end

    test "information about all snapshots" do
      assert {:ok, %{status_code: 200}} = Snapshot.get(@test_url, @repo)
    end

    test "information about a specific snapshot" do
      Snapshot.create(@test_url, @repo, @snapshot_5, %{indices: @index_5})
      assert {:ok, %{status_code: 200}} = Snapshot.get(@test_url, @repo, @snapshot_5)
    end
  end

  describe "deleting a snapshot" do
    test "snapshot doesn't exist" do
      assert {:ok, %{status_code: 404}} = Snapshot.delete(@test_url, @repo, "nonexistent")
    end

    test "snapshot is deleted" do
      Snapshot.create(@test_url, @repo, @snapshot_5, %{indices: @index_5})

      wait lin_backoff(500, 1) |> expiry(5_000) do
        (
          {:ok, response} = Snapshot.status(@test_url, @repo, @snapshot_5)
          snapshot = List.first(response.body["snapshots"])
          snapshot["state"] == "SUCCESS"
        )

        then

        (
          assert {:ok, %{status_code: 200}} = Snapshot.delete(@test_url, @repo, @snapshot_5)
          assert {:ok, %{status_code: 404}} = Snapshot.get(@test_url, @repo, @snapshot_5)
        )
      end
    end
  end
end

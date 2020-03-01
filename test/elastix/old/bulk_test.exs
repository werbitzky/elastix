defmodule Elastix.Old.BulkTest do
  use ExUnit.Case
  alias Elastix.Index
  alias Elastix.Bulk
  alias Elastix.Document
  @old false

  @test_url Elastix.config(:test_url)
  @test_index Elastix.config(:test_index)

  setup do
    Index.delete(@test_url, @test_index)

    :ok
  end

  test "make_path should make url from index name, type, and query params" do
    if @old do
    assert Bulk.make_path(@test_index, "tweet", version: 34, ttl: "1d") ==
             "/#{@test_index}/tweet/_bulk?version=34&ttl=1d"
    end
  end

  test "make_path should make url from index name and query params" do
    if @old do
    assert Bulk.make_path(@test_index, nil, version: 34, ttl: "1d") ==
             "/#{@test_index}/_bulk?version=34&ttl=1d"
    end
  end

  test "make_path should make url from query params" do
    if @old do
    assert Bulk.make_path(nil, nil, version: 34, ttl: "1d") == "/_bulk?version=34&ttl=1d"
    end
  end

  test "bulk accepts httpoison options" do
    lines = [
        %{index: %{_id: "1"}},
        %{field: "value1"},
        %{index: %{_id: "2"}},
        %{field: "value2"}
      ]
    {:error, %HTTPoison.Error{reason: :timeout}} =
      Bulk.post @test_url, lines, index: @test_index, type: "message", httpoison_options: [recv_timeout: 0]
  end

  describe "test bulks with index and type in URL" do
    setup do
      {:ok,
       lines: [
         %{index: %{_id: "1"}},
         %{field: "value1"},
         %{index: %{_id: "2"}},
         %{field: "value2"}
       ]}
    end

    test "post bulk should execute it", %{lines: lines} do
      {:ok, response} = Bulk.post(@test_url, lines, index: @test_index, type: "message")

      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "1")

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "2")
    end

    test "post bulk with raw body should execute it", %{lines: lines} do
      {:ok, response} =
        Bulk.post_raw(
          @test_url,
          Enum.map(lines, fn line -> Poison.encode!(line) <> "\n" end),
          index: @test_index,
          type: "message"
        )

      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "1")

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "2")
    end

    test "post bulk sending iolist should execute it", %{lines: lines} do
      {:ok, response} =
        Bulk.post_to_iolist(@test_url, lines, index: @test_index, type: "message")

      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "1")

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "2")
    end
  end

  describe "test bulks with index only in URL" do
    setup do
      {:ok,
       lines: [
         %{index: %{_id: "1", _type: "message"}},
         %{field: "value1"},
         %{index: %{_id: "2", _type: "message"}},
         %{field: "value2"}
       ]}
    end

    test "post bulk should execute it", %{lines: lines} do
      {:ok, response} = Bulk.post(@test_url, lines, index: @test_index)

      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "1")

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "2")
    end

    test "post bulk with raw body should execute it", %{lines: lines} do
      {:ok, response} =
        Bulk.post_raw(
          @test_url,
          Enum.map(lines, fn line -> Poison.encode!(line) <> "\n" end),
          index: @test_index
        )

      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "1")

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "2")
    end

    test "post bulk sending iolist should execute it", %{lines: lines} do
      {:ok, response} = Bulk.post_to_iolist(@test_url, lines, index: @test_index)

      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "1")

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "2")
    end
  end

  describe "test bulks without index nor type in URL" do
    setup do
      {:ok,
       lines: [
         %{index: %{_id: "1", _type: "message", _index: @test_index}},
         %{field: "value1"},
         %{index: %{_id: "2", _type: "message", _index: @test_index}},
         %{field: "value2"}
       ]}
    end

    test "post bulk should execute it", %{lines: lines} do
      {:ok, response} = Bulk.post(@test_url, lines)

      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "1")

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "2")
    end

    test "post bulk with raw body should execute it", %{lines: lines} do
      {:ok, response} =
        Bulk.post_raw(
          @test_url,
          Enum.map(lines, fn line -> Poison.encode!(line) <> "\n" end)
        )

      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "1")

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "2")
    end

    test "post bulk sending iolist should execute it", %{lines: lines} do
      {:ok, response} = Bulk.post_to_iolist(@test_url, lines)

      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "1")

      assert {:ok, %{status_code: 200}} =
               Document.get(@test_url, @test_index, "message", "2")
    end
  end
end

defmodule Elastix.BulkTest do
  use ExUnit.Case
  alias Elastix.Index
  alias Elastix.Bulk
  alias Elastix.Document

  import ExUnit.CaptureLog

  @test_url Elastix.config(:test_url)
  @test_index Elastix.config(:test_index)

  setup do
    Index.delete(@test_url, @test_index)

    :ok
  end

  describe "make_path/2" do
    test "makes path from index name and type" do
      assert Bulk.make_path(@test_index, "tweet") == "/#{@test_index}/tweet/_bulk"
    end

    test "makes path from index name" do
      assert Bulk.make_path(@test_index, nil) == "/#{@test_index}/_bulk"
    end

    test "makes path with default" do
      assert Bulk.make_path(nil, nil) == "/_bulk"
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

    test "post bulk", %{lines: lines} do
      {:ok, response} = Bulk.post(@test_url, lines, index: @test_index, type: "message")
      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "1")
      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "2")
    end

    test "post bulk with raw body", %{lines: lines} do
      encoded = Enum.map(lines, fn line -> Poison.encode!(line) <> "\n" end)
      {:ok, response} = Bulk.post_raw(@test_url, encoded, index: @test_index, type: "message")
      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "1")
      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "2")
    end

    test "post_to_iolist/4 should log deprecation warning", %{lines: lines} do
      assert capture_log(fn ->
        Bulk.post_to_iolist(@test_url, lines, index: @test_index, type: "message")
      end) =~ "This function is deprecated and will be removed in future releases; use Elastix.Bulk.post/4 instead"
    end

    @tag capture_log: true
    test "post bulk sending iolist should execute it", %{lines: lines} do
      {:ok, response} =
        Bulk.post_to_iolist(@test_url, lines, index: @test_index, type: "message")
      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "1")
      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "2")
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

      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "1")
      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "2")
    end

    test "post bulk with raw body should execute it", %{lines: lines} do
      encoded = Enum.map(lines, fn line -> Poison.encode!(line) <> "\n" end)
      {:ok, response} = Bulk.post_raw(@test_url, encoded, index: @test_index)
      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "1")
      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "2")
    end

    @tag capture_log: true
    test "post bulk sending iolist should execute it", %{lines: lines} do
      {:ok, response} = Bulk.post_to_iolist(@test_url, lines, index: @test_index)
      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "1")
      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "2")
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

      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "1")
      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "2")
    end

    test "post bulk with raw body should execute it", %{lines: lines} do
      encoded = Enum.map(lines, fn line -> Poison.encode!(line) <> "\n" end)
      {:ok, response} = Bulk.post_raw(@test_url, encoded)
      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "1")
      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "2")
    end

    @tag capture_log: true
    test "post bulk sending iolist should execute it", %{lines: lines} do
      {:ok, response} = Bulk.post_to_iolist(@test_url, lines)
      assert response.status_code == 200

      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "1")
      assert {:ok, %{status_code: 200}} = Document.get(@test_url, @test_index, "message", "2")
    end
  end
end

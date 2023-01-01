defmodule Elastix.SearchTest do
  use ExUnit.Case
  alias Elastix.Search
  alias Elastix.Index
  alias Elastix.Document

  @test_url Elastix.config(:test_url)
  @test_index Elastix.config(:test_index)
  @test_index_2 Elastix.config(:test_index_2)
  @document_data %{
    user: "werbitzky",
    post_date: "2009-11-15T14:12:12",
    message: "trying out Elasticsearch"
  }
  @query_data %{
    query: %{
      term: %{user: "werbitzky"}
    }
  }
  @scroll_query %{
    size: 5,
    query: %{match_all: %{}},
    sort: ["_doc"]
  }

  setup do
    Index.delete(@test_url, @test_index)
    Index.delete(@test_url, @test_index_2)

    :ok
  end

  describe "make_path/2" do
    test "makes path from index and types" do
      path = Search.make_path(@test_index, ["tweet", "product"])
      assert path == "/#{@test_index}/tweet,product/_search"
    end

    test "makes path with API type" do
      path = Search.make_path(@test_index, ["tweet", "product"], "_count")
      assert path == "/#{@test_index}/tweet,product/_count"
    end
  end

  test "search should return with status 200" do
    Document.index(@test_url, @test_index, "message", 1, @document_data, refresh: true)

    {:ok, response} = Search.search(@test_url, @test_index, [], @query_data)

    assert response.status_code == 200
  end

  test "search accepts httpoison options" do
    Document.index(@test_url, @test_index, "message", 1, @document_data, refresh: true)

    {:error, %HTTPoison.Error{reason: :timeout}} =
      Search.search(@test_url, @test_index, [], @query_data, [], recv_timeout: 0)
  end

  test "search accepts a list of indexes" do
    Document.index(@test_url, @test_index, "message", 1, @document_data, refresh: true)
    Document.index(@test_url, @test_index_2, "message", 1, @document_data, refresh: true)

    {:ok, %HTTPoison.Response{body: body} = response} =
      Search.search(@test_url, [@test_index, @test_index_2], [], @query_data)

    assert response.status_code == 200
    assert length(body["hits"]["hits"]) === 2
  end

  test "search accepts a list of requests" do
    Document.index(@test_url, @test_index, "message", 1, @document_data, refresh: true)
    Document.index(@test_url, @test_index, "message", 2, @document_data, refresh: true)

    {:ok, response} =
      Search.search(@test_url, @test_index, [], [%{}, @query_data, %{}, @query_data])

    assert [_first, _second] = response.body["responses"]
    assert response.status_code == 200
  end

  describe "scroll/3" do

    test "can scroll through results" do
      for i <- 1..10 do
        Document.index(@test_url, @test_index, @document_data, %{id: i}, refresh: true)
      end

      {:ok, %{status_code: 200, body: body}} =
        Search.search(@test_url, @test_index, [], @scroll_query, scroll: "1m")
      assert length(body["hits"]["hits"]) === 5

      {:ok, %{status_code: 200, body: body}} =
        Search.scroll(@test_url, %{scroll: "1m", scroll_id: body["_scroll_id"]})
      assert length(body["hits"]["hits"]) === 5

      {:ok, %{status_code: 200, body: body}} =
        Search.scroll(@test_url, %{scroll: "1m", scroll_id: body["_scroll_id"]})

      assert length(body["hits"]["hits"]) === 0
    end

  end

  test "count returns status 200" do
    Document.index(@test_url, @test_index, "message", 1, @document_data, refresh: true)

    {:ok, response} = Search.count(@test_url, @test_index, [], @query_data)

    assert response.status_code == 200
    assert response.body["count"] == 1
  end
end

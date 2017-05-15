defmodule Elastix.SearchTest do
  use ExUnit.Case
  alias Elastix.Search
  alias Elastix.Index
  alias Elastix.Document

  @test_url Elastix.config(:test_url)
  @test_index Elastix.config(:test_index)
  @document_data %{
    user: "werbitzky",
    post_date: "2009-11-15T14:12:12",
    message: "trying out Elasticsearch"
  }
  @query_data %{
    query: %{
      term: %{ user: "werbitzky" }
    }
  }




  setup do
    Index.delete(@test_url, @test_index)

    :ok
  end

  test "make_path should make path from id and url" do
    path = Search.make_path(@test_index, ["tweet", "product"], [ttl: "1d", timeout: 123])
    assert path == "/#{@test_index}/tweet,product/_search?ttl=1d&timeout=123"
  end

  test "search should return with status 200" do
    Document.index @test_url, @test_index, "message", 1, @document_data, [refresh: true]

    {:ok, response} = Search.search @test_url, @test_index, [], @query_data

    assert response.status_code == 200
  end

  test "search accepts httpoison options" do
    Document.index @test_url, @test_index, "message", 1, @document_data, [refresh: true]

    {:error, %HTTPoison.Error{reason: :timeout}} =
      Search.search @test_url, @test_index, [], @query_data, [], recv_timeout: 0
  end
end

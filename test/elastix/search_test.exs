defmodule Elastix.SearchTest do
  use ExUnit.Case
  alias Elastix.Search
  alias Elastix.Index
  alias Elastix.Document

  @test_index Elastix.config(:test_index)

  setup do
    Index.delete(@test_index)

    :ok
  end

  test "make_path should make path from id and url" do
    path = Search.make_path(@test_index, ["tweet", "product"], [ttl: "1d", timeout: 123])
    assert path == "/#{@test_index}/tweet,product/_search?ttl=1d&timeout=123"
  end

  test "search should return with status 200" do
    data = %{
      user: "werbitzky",
      post_date: "2009-11-15T14:12:12",
      message: "trying out Elasticsearch"
    }

    Document.index @test_index, "message", 1, data, [refresh: true]

    data = %{
      query: %{
        term: %{ user: "werbitzky" }
      }
    }
    response = Search.search @test_index, [], data

    assert response.status_code == 200
  end
end

defmodule Elastix.DocumentTest do
  use ExUnit.Case
  alias Elastix.Index
  alias Elastix.Document

  @test_url Elastix.config(:test_url)
  @test_index Elastix.config(:test_index)
  @data %{
    user: "örelbörel",
    post_date: "2009-11-15T14:12:12",
    message: "trying out Elasticsearch"
  }


  setup do
    Index.delete(@test_url, @test_index)

    :ok
  end

  test "make_path should make url from index name, type, query params, id, and suffix" do
    assert Document.make_path(@test_index, "tweet", [version: 34, ttl: "1d"], 2, "_update") == "/#{@test_index}/tweet/2/_update?version=34&ttl=1d"
  end

  test "index should create and index with data" do
    {:ok, response} = Document.index @test_url, @test_index, "message", 1, @data

    assert response.status_code == 201
    assert response.body["_id"] == "1"
    assert response.body["_index"] == @test_index
    assert response.body["_type"] == "message"
    assert response.body["created"] == true
  end

  test "index_new should index data without an id" do
    {:ok, response} = Document.index_new @test_url, @test_index, "message", @data

    assert response.status_code == 201
    assert response.body["_id"]
    assert response.body["_index"] == @test_index
    assert response.body["_type"] == "message"
    assert response.body["created"] == true
  end

  test "get should return 404 if not index was created" do
    {:ok, response} = Document.get @test_url, @test_index, "message", 1

    assert response.status_code == 404
  end

  test "get should return data with 200 after index" do
    Document.index @test_url, @test_index, "message", 1, @data
    {:ok, response} = Document.get @test_url, @test_index, "message", 1
    body = response.body

    assert response.status_code == 200
    assert body["_source"]["user"] == "örelbörel"
    assert body["_source"]["post_date"] == "2009-11-15T14:12:12"
    assert body["_source"]["message"] == "trying out Elasticsearch"
  end

  test "delete should delete created index" do
    Document.index @test_url, @test_index, "message", 1, @data

    {:ok, response} = Document.get @test_url, @test_index, "message", 1
    assert response.status_code == 200

    {:ok, response} = Document.delete @test_url, @test_index, "message", 1
    assert response.status_code == 200

    {:ok, response} = Document.get @test_url, @test_index, "message", 1
    assert response.status_code == 404
  end

  test "update can partially update document" do
    Document.index @test_url, @test_index, "message", 1, @data

    new_post_date = "2017-03-17T14:12:12"
    patch = %{ doc: %{ post_date: new_post_date } }

    {:ok, response} = Document.update @test_url, @test_index, "message", 1, patch
    assert response.status_code == 200

    {:ok, %{body: body, status_code: status_code}} = Document.get @test_url, @test_index, "message", 1

    assert status_code == 200
    assert body["_source"]["user"] == "örelbörel"
    assert body["_source"]["post_date"] == new_post_date
    assert body["_source"]["message"] == "trying out Elasticsearch"
  end

  test "can get multiple documents (multi get)" do
    Document.index @test_url, @test_index, "message", 1, @data
    Document.index @test_url, @test_index, "message", 2, @data

    query = %{"docs" =>
      [
        %{
          "_index" => @test_index,
          "_type" => "message",
          "_id" => "1"
        },
        %{
          "_index" => @test_index,
          "_type" => "message",
          "_id" => "2"
        }
      ]
    }
    {:ok, %{body: body, status_code: status_code}} = Document.mget @test_url, query

    assert status_code === 200
    assert length(body["docs"]) == 2
  end

  test "can get multiple documents (multi get with index)" do
    Document.index @test_url, @test_index, "message", 1, @data
    Document.index @test_url, @test_index, "message", 2, @data

    query = %{"docs" =>
      [
        %{
          "_type" => "message",
          "_id" => "1"
        },
        %{
          "_type" => "message",
          "_id" => "2"
        }
      ]
    }
    {:ok, %{body: body, status_code: status_code}} = Document.mget @test_url, query, @test_index

    assert status_code === 200
    assert length(body["docs"]) == 2
  end

  test "can get multiple documents (multi get with index and type)" do
    Document.index @test_url, @test_index, "message", 1, @data
    Document.index @test_url, @test_index, "message", 2, @data

    query = %{"docs" =>
      [
        %{
          "_id" => "1"
        },
        %{
          "_id" => "2"
        }
      ]
    }
    {:ok, %{body: body, status_code: status_code}} = Document.mget @test_url, query, @test_index, "message"

    assert status_code === 200
    assert length(body["docs"]) == 2
  end
end

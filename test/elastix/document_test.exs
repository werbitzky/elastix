defmodule Elastix.DocumentTest do
  require Logger
  use ExUnit.Case
  alias Elastix.{Document, Index, Search}
  alias Elastix.HTTP

  @test_url Elastix.config(:test_url)
  @test_index Elastix.config(:test_index)
  @data %{
    user: "örelbörel",
    post_date: "2009-11-15T14:12:12",
    message: "trying out Elasticsearch"
  }

  setup_all do
    # Query the Elasticsearch instance to determine what version it is running
    # so we can use it in tests.
    {:ok, response} = HTTP.get(@test_url)
    {version, _rest} = Float.parse(response.body["version"]["number"])

    {:ok, version: version}
  end


  setup do
    Index.delete(@test_url, @test_index)

    :ok
  end

  describe "make_path/5" do
    test "makes path from index name, type, query params, id, and suffix" do
      assert Document.make_path_old(@test_index, "tweet", [version: 34, ttl: "1d"], 2, "_update") ==
        "/#{@test_index}/tweet/2/_update?version=34&ttl=1d"
    end

    test "makes path from index name, type, and query params" do
      assert Document.make_path_old(@test_index, "tweet", version: 34, ttl: "1d") ==
        "/#{@test_index}/tweet?version=34&ttl=1d"
    end
  end

  describe "make_path/2" do
    test "handles all options" do
      assert Document.make_path(@test_index, %{id: 42}) == "/#{@test_index}/_doc/42"
      assert Document.make_path(@test_index) == "/#{@test_index}/_doc/"
    end
  end

  describe "index/6" do
    test "old API indexes document", %{version: version} do
      {:ok, response} = Document.index(@test_url, @test_index, "message", 1, @data)

      assert response.status_code == 201
      assert response.body["_id"] == "1"
      assert response.body["_index"] == @test_index
      assert response.body["_type"] == "message"
      if version >= 6.0 do
        assert response.body["result"] == "created"
      else
        assert response.body["created"] == true
      end
    end

    test "new API indexes document" do
      {:ok, response} = Document.index(@test_url, @test_index, @data, %{id: 1})
      assert response.status_code == 201
      assert response.body["_id"] == "1"
      assert response.body["_index"] == @test_index
      assert response.body["result"] == "created"
    end

  end

  test "index_new should index data without an id", %{version: version} do
    {:ok, response} = Document.index_new(@test_url, @test_index, "message", @data)

    assert response.status_code == 201
    assert response.body["_id"]
    assert response.body["_index"] == @test_index
    assert response.body["_type"] == "message"
    if version >= 6.0 do
      assert response.body["result"] == "created"
    else
      assert response.body["created"] == true
    end
  end

  describe "get/5 old API" do
    test "get returns 404 on unknown index" do
      {:ok, response} = Document.get(@test_url, @test_index, "message", 1)
      assert response.status_code == 404
    end

    test "get returns data with 200 after index" do
      Document.index(@test_url, @test_index, "message", 1, @data)
      {:ok, %{status_code: 200, body: body}} = Document.get(@test_url, @test_index, "message", 1)

      assert body["_source"]["user"] == "örelbörel"
      assert body["_source"]["post_date"] == "2009-11-15T14:12:12"
      assert body["_source"]["message"] == "trying out Elasticsearch"
    end
  end

  describe "get/5 new API" do
    test "get returns 404 on unknown index" do
      {:ok, response} = Document.get(@test_url, @test_index, 1)
      assert response.status_code == 404
    end

    test "get returns data with 200 after index" do
      {:ok, %{status_code: 201}} = Document.index(@test_url, @test_index, @data, %{id: 1})
      {:ok, %{status_code: 200, body: body}} = Document.get(@test_url, @test_index, 1)

      assert body["_source"]["user"] == "örelbörel"
      assert body["_source"]["post_date"] == "2009-11-15T14:12:12"
      assert body["_source"]["message"] == "trying out Elasticsearch"
    end
  end

  describe "delete/5 old API" do

    test "delete should delete created index" do
      Document.index(@test_url, @test_index, "message", 1, @data)

      {:ok, response} = Document.get(@test_url, @test_index, "message", 1)
      assert response.status_code == 200

      {:ok, response} = Document.delete(@test_url, @test_index, "message", 1)
      assert response.status_code == 200

      {:ok, response} = Document.get(@test_url, @test_index, "message", 1)
      assert response.status_code == 404
    end

    test "delete by query should remove all docs that match" do
      Document.index(@test_url, @test_index, "message", 1, @data, refresh: true)
      Document.index(@test_url, @test_index, "message", 2, @data, refresh: true)

      no_match = Map.put(@data, :user, "no match")
      Document.index(@test_url, @test_index, "message", 3, no_match, refresh: true)

      match_all_query = %{"query" => %{"match_all" => %{}}}

      {:ok, response} = Search.search(@test_url, @test_index, ["message"], match_all_query)
      assert response.status_code == 200
      assert response.body["hits"]["total"] == 3

      query = %{"query" => %{"match" => %{"user" => "örelbörel"}}}

      {:ok, response} =
        Document.delete_matching(@test_url, @test_index, query, refresh: true)

      assert response.status_code == 200

      {:ok, response} = Search.search(@test_url, @test_index, ["message"], match_all_query)
      assert response.status_code == 200
      assert response.body["hits"]["total"] == 1
    end
  end

  describe "delete/5 new API" do

    test "deletes created index" do
      Document.index(@test_url, @test_index, @data, %{id: 1})

      {:ok, response} = Document.get(@test_url, @test_index, 1)
      assert response.status_code == 200

      {:ok, response} = Document.delete(@test_url, @test_index, 1)
      assert response.status_code == 200

      {:ok, response} = Document.get(@test_url, @test_index, 1)
      assert response.status_code == 404
    end

    test "delete by query should remove all docs that match" do
      Document.index(@test_url, @test_index, @data, %{id: 1}, refresh: true)
      Document.index(@test_url, @test_index, @data, %{id: 2}, refresh: true)

      no_match = Map.put(@data, :user, "no match")
      Document.index(@test_url, @test_index, no_match, %{id: 3}, refresh: true)

      match_all_query = %{"query" => %{"match_all" => %{}}}

      {:ok, response} = Search.search(@test_url, @test_index, [], match_all_query)
      assert response.status_code == 200
      assert response.body["hits"]["total"] == 3

      query = %{"query" => %{"match" => %{"user" => "örelbörel"}}}

      {:ok, response} = Document.delete_matching(@test_url, @test_index, query, refresh: true)
      assert response.status_code == 200

      {:ok, response} = Search.search(@test_url, @test_index, [], match_all_query)
      assert response.status_code == 200
      assert response.body["hits"]["total"] == 1
    end
  end

  test "update can partially update document" do
    Document.index(@test_url, @test_index, "message", 1, @data)

    new_post_date = "2017-03-17T14:12:12"
    patch = %{doc: %{post_date: new_post_date}}

    {:ok, response} = Document.update(@test_url, @test_index, "message", 1, patch)
    assert response.status_code == 200

    {:ok, %{body: body, status_code: status_code}} =
      Document.get(@test_url, @test_index, "message", 1)

    assert status_code == 200
    assert body["_source"]["user"] == "örelbörel"
    assert body["_source"]["post_date"] == new_post_date
    assert body["_source"]["message"] == "trying out Elasticsearch"
  end

  describe "mget/5 old API" do

    test "can get multiple documents (multi get)" do
      Document.index(@test_url, @test_index, "message", 1, @data)
      Document.index(@test_url, @test_index, "message", 2, @data)

      query = %{
        "docs" => [
          %{"_index" => @test_index, "_type" => "message", "_id" => "1"},
          %{"_index" => @test_index,
            "_type" => "message",
            "_id" => "2"
          }
        ]
      }

      {:ok, %{body: body, status_code: status_code}} = Document.mget(@test_url, query)

      assert status_code === 200
      assert length(body["docs"]) == 2
    end

    test "can get multiple documents (multi get with index)" do
      Document.index(@test_url, @test_index, "message", 1, @data)
      Document.index(@test_url, @test_index, "message", 2, @data)

      query = %{
        "docs" => [
          %{"_type" => "message", "_id" => "1"},
          %{"_type" => "message", "_id" => "2"}
        ]
      }

      {:ok, %{body: body, status_code: status_code}} =
        Document.mget(@test_url, query, @test_index)

      assert status_code === 200
      assert length(body["docs"]) == 2
    end

    test "can get multiple documents (multi get with index and type)" do
      Document.index(@test_url, @test_index, "message", 1, @data)
      Document.index(@test_url, @test_index, "message", 2, @data)

      query = %{
        "docs" => [
          %{"_id" => "1"},
          %{"_id" => "2"}
        ]
      }

      {:ok, %{body: body, status_code: status_code}} =
        Document.mget(@test_url, query, @test_index, "message")

      assert status_code === 200
      assert length(body["docs"]) == 2
    end
  end

  describe "mget/5 new API" do
    test "can get multiple documents (multi get)" do
      Document.index(@test_url, @test_index, @data, %{id: 1})
      Document.index(@test_url, @test_index, @data, %{id: 2})

      query = %{
        "docs" => [
          %{"_index" => @test_index, "_id" => "1"},
          %{"_index" => @test_index, "_id" => "2"}
        ]
      }

      {:ok, %{body: body, status_code: status_code}} = Document.mget(@test_url, query)

      assert status_code === 200
      assert length(body["docs"]) == 2
    end

    test "can get multiple documents (multi get with index)" do
      Document.index(@test_url, @test_index, @data, %{id: 1})
      Document.index(@test_url, @test_index, @data, %{id: 2})

      query = %{
        "docs" => [
          %{"_id" => "1"},
          %{"_id" => "2"}
        ]
      }

      {:ok, response} = Document.mget(@test_url, query, @test_index)
      assert response.status_code === 200
      assert length(response.body["docs"]) == 2
    end

    test "can get multiple documents" do
      Document.index(@test_url, @test_index, @data, %{id: 1})
      Document.index(@test_url, @test_index, @data, %{id: 2})

      query = %{
        "docs" => [
          %{"_id" => "1"},
          %{"_id" => "2"}
        ]
      }

      {:ok, response} = Document.mget(@test_url, query, @test_index)
      assert response.status_code == 200
      assert length(response.body["docs"]) == 2
    end
  end

end

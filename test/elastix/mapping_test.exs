defmodule Elastix.MappingTest do
  use ExUnit.Case
  alias Elastix.Index
  alias Elastix.Mapping
  alias Elastix.Document
  alias Elastix.HTTP

  @test_url Elastix.config(:test_url)
  @test_index Elastix.config(:test_index)
  @test_index2 Elastix.config(:test_index) <> "_2"
  @mapping %{
    properties: %{
      user: %{type: "integer"},
      message: %{type: "boolean"}
    }
  }
  @target_mapping %{
    "properties" => %{
      "user" => %{"type" => "integer"},
      "message" => %{"type" => "boolean"}
    }
  }
  @data %{
    user: 12,
    message: true
  }

  setup_all do
    # Query the Elasticsearch instance to determine what version it is running
    # so we can use it in tests.
    {:ok, response} = HTTP.get(@test_url)
    version_string = response.body["version"]["number"]
    version = Elastix.version_to_tuple(version_string)

    {:ok, version: version}
  end

  setup do
    Index.delete(@test_url, @test_index)
    Index.delete(@test_url, @test_index2)

    :ok
  end

  test "put_path/4 handles all combinations of params" do
    # Old
    assert Mapping.put_path("foo", "biz", %{}, []) == "/foo/_mapping/biz"
    assert Mapping.put_path(["foo"], "biz", %{}, []) == "/foo/_mapping/biz"
    assert Mapping.put_path(["foo", "bar"], "biz", %{}, []) == "/foo,bar/_mapping/biz"
    assert Mapping.put_path(["foo", "bar"], "biz", %{}, version: 34, ttl: "1d") ==
      "/foo,bar/_mapping/biz?version=34&ttl=1d"

    assert Mapping.put_path("foo", %{}, [], []) == "/foo/_mapping"
    assert Mapping.put_path("foo", %{}, [version: 34, ttl: "1d"], []) ==
      "/foo/_mapping?version=34&ttl=1d"
  end

  test "get_path/3 handles all combinations of params" do
    # Old
    assert Mapping.get_path("foo", "biz", []) == "/foo/_mapping/biz"
    assert Mapping.get_path(["foo"], "biz", []) == "/foo/_mapping/biz"
    assert Mapping.get_path(["foo"], ["biz"], []) == "/foo/_mapping/biz"
    assert Mapping.get_path("foo", ["biz"], []) == "/foo/_mapping/biz"
    assert Mapping.get_path(["foo", "bar"], ["biz", "baz"], []) == "/foo,bar/_mapping/biz,baz"
    assert Mapping.get_path(["foo", "bar"], ["biz", "baz"], version: 34, ttl: "1d") ==
      "/foo,bar/_mapping/biz,baz?version=34&ttl=1d"

    # New
    assert Mapping.get_path("foo", [], []) == "/foo/_mapping"
    assert Mapping.get_path("foo", [version: 34, ttl: "1d"], []) ==
      "/foo/_mapping?version=34&ttl=1d"
  end

  test "make_all_path/2 makes url from types" do
    assert Mapping.make_all_path(["tweet"]) == "/_mapping/tweet"
  end

  test "put mapping with no index should error" do
    {:ok, response} = Mapping.put(@test_url, @test_index, "message", @mapping, include_type_name: true)

    assert response.status_code == 404
  end

  test "put should put mapping" do
    Index.create(@test_url, @test_index, %{})
    {:ok, response} = Mapping.put(@test_url, @test_index, "message", @mapping, include_type_name: true)

    assert response.status_code == 200
    assert response.body["acknowledged"] == true
  end

  test "get with non existing index should return error" do
    {:ok, response} = Mapping.get(@test_url, @test_index, "message", include_type_name: true)

    assert response.status_code == 404
  end

  test "get with non existing mapping", %{version: version} do
    Index.create(@test_url, @test_index, %{})

    cond do
      version >= {6, 0, 0} ->
        {:ok, response} = Mapping.get(@test_url, @test_index, include_type_name: false)
        assert response.body == %{@test_index => %{"mappings" => %{}}}
        assert response.status_code == 200
      version >= {5, 5, 0} ->
        {:ok, response} = Mapping.get(@test_url, @test_index, "message")
        assert response.body["error"]["reason"] == "type[[message]] missing"
        assert response.status_code == 404
      true ->
        {:ok, response} = Mapping.get(@test_url, @test_index, "message")
        assert response.body == %{}
        assert response.status_code == 404
    end

  end

  test "get mapping should return mapping" do
    Index.create(@test_url, @test_index, %{})
    Mapping.put(@test_url, @test_index, "message", @mapping, include_type_name: true)
    {:ok, response} = Mapping.get(@test_url, @test_index, "message", include_type_name: true)

    assert response.status_code == 200
    assert response.body[@test_index]["mappings"]["message"] == @target_mapping
  end

  test "get mapping for several types should return several mappings", %{version: version} do
    Index.create(@test_url, @test_index, %{})

    if version >= {6, 0, 0} do
      Mapping.put(@test_url, @test_index, "message", @mapping, include_type_name: true)
      Mapping.put(@test_url, @test_index, "comment", @mapping, include_type_name: true)

      {:ok, response} = Mapping.get(@test_url, @test_index, ["message", "comment"], include_type_name: true)
      assert response.status_code == 404
    else
      Mapping.put(@test_url, @test_index, "message", @mapping, include_type_name: true)
      Mapping.put(@test_url, @test_index, "comment", @mapping, include_type_name: true)

      {:ok, response} = Mapping.get(@test_url, @test_index, ["message", "comment"], include_type_name: true)
      assert response.status_code == 200
      assert response.body[@test_index]["mappings"]["message"] == @target_mapping
      assert response.body[@test_index]["mappings"]["comment"] == @target_mapping
    end
  end

  test "get_all mappings should return mappings for all indexes and types" do
    Index.create(@test_url, @test_index, %{})
    Index.create(@test_url, @test_index2, %{})
    Mapping.put(@test_url, @test_index, "message", @mapping, include_type_name: true)
    Mapping.put(@test_url, @test_index2, "comment", @mapping, include_type_name: true)
    {:ok, response} = Mapping.get_all(@test_url, include_type_name: true)

    assert response.status_code == 200
    assert response.body[@test_index]["mappings"]["message"] == @target_mapping
    assert response.body[@test_index2]["mappings"]["comment"] == @target_mapping
  end

  test "get_all_with_type mappings should return mapping for specifieds types in all indexes" do
    Index.create(@test_url, @test_index, %{})
    Index.create(@test_url, @test_index2, %{})
    Mapping.put(@test_url, @test_index, "message", @mapping, include_type_name: true)
    Mapping.put(@test_url, @test_index2, "comment", @mapping, include_type_name: true)
    {:ok, response} = Mapping.get_all_with_type(@test_url, ["message", "comment"], include_type_name: true)

    assert response.status_code == 200
    assert response.body[@test_index]["mappings"]["message"] == @target_mapping
    assert response.body[@test_index2]["mappings"]["comment"] == @target_mapping
  end

  test "put document with mapping should put document", %{version: version} do
    Index.create(@test_url, @test_index, %{})
    Mapping.put(@test_url, @test_index, "message", @mapping)

    {:ok, response} = Document.index(@test_url, @test_index, "message", 1, @data)

    assert response.status_code == 201
    assert response.body["_id"] == "1"
    assert response.body["_index"] == @test_index
    assert response.body["_type"] == "message"

    if version >= {6, 0, 0} do
      assert response.body["result"] == "created"
    else
      assert response.body["created"] == true
    end
  end
end

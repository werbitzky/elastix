defmodule Elastix.MappingTest do
  use ExUnit.Case
  alias Elastix.Index
  alias Elastix.Mapping
  alias Elastix.Document

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


  setup do
    Index.delete(@test_url, @test_index)
    Index.delete(@test_url, @test_index2)

    :ok
  end

  defp elasticsearch_version do
    %HTTPoison.Response{body: %{"version" => %{"number" => v}}, status_code: 200}
      = Elastix.HTTP.get!(@test_url)

    v |> String.split([".", "-"]) |> Enum.take(3) |> Enum.map(&String.to_integer/1) |> List.to_tuple
  end

  test "make_path should make url from index names, types, and query params" do
    assert Mapping.make_path([@test_index], ["tweet"], version: 34, ttl: "1d") == "/#{@test_index}/_mapping/tweet?version=34&ttl=1d"
  end

  test "make_all_path should make url from types, and query params" do
    assert Mapping.make_all_path(["tweet"], version: 34, ttl: "1d") == "/_mapping/tweet?version=34&ttl=1d"
  end

  test "make_all_path should make url from query params" do
    assert Mapping.make_all_path(version: 34, ttl: "1d") == "/_mapping?version=34&ttl=1d"
  end

  test "put mapping with no index should error" do
    {:ok, response} = Mapping.put @test_url, @test_index, "message", @mapping

    assert response.status_code == 404
  end

  test "put should put mapping" do
    Index.create @test_url, @test_index, %{}
    {:ok, response} = Mapping.put @test_url, @test_index, "message", @mapping

    assert response.status_code == 200
    assert response.body["acknowledged"] == true
  end

  test "get with non existing index should return error" do
    {:ok, response} = Mapping.get @test_url, @test_index, "message"

    assert response.status_code == 404
  end

  test "get with non existing mapping" do
    Index.create @test_url, @test_index, %{}
    {:ok, response} = Mapping.get @test_url, @test_index, "message"

    if elasticsearch_version() >= {5,5,0} do
      assert response.body["error"]["reason"] == "type[[message]] missing"
    else
      assert response.body == %{}
    end
  end

  test "get mapping should return mapping" do
    Index.create @test_url, @test_index, %{}
    Mapping.put @test_url, @test_index, "message", @mapping
    {:ok, response} = Mapping.get @test_url, @test_index, "message"

    assert response.status_code == 200
    assert response.body[@test_index]["mappings"]["message"] == @target_mapping
  end

  test "get mapping for several types should return several mappings" do
    Index.create @test_url, @test_index, %{}
    Mapping.put @test_url, @test_index, "message", @mapping
    Mapping.put @test_url, @test_index, "comment", @mapping
    {:ok, response} = Mapping.get @test_url, @test_index, ["message", "comment"]

    assert response.status_code == 200
    assert response.body[@test_index]["mappings"]["message"] == @target_mapping
    assert response.body[@test_index]["mappings"]["comment"] == @target_mapping
  end

  test "get_all mappings should return mappings for all indexes and types" do
    Index.create @test_url, @test_index, %{}
    Index.create @test_url, @test_index2, %{}
    Mapping.put @test_url, @test_index, "message", @mapping
    Mapping.put @test_url, @test_index2, "comment", @mapping
    {:ok, response} = Mapping.get_all @test_url

    assert response.status_code == 200
    assert response.body[@test_index]["mappings"]["message"] == @target_mapping
    assert response.body[@test_index2]["mappings"]["comment"] == @target_mapping
  end

  test "get_all_with_type mappings should return mapping for specifieds types in all indexes" do
    Index.create @test_url, @test_index, %{}
    Index.create @test_url, @test_index2, %{}
    Mapping.put @test_url, @test_index, "message", @mapping
    Mapping.put @test_url, @test_index2, "comment", @mapping
    {:ok, response} = Mapping.get_all_with_type @test_url, ["message", "comment"]

    assert response.status_code == 200
    assert response.body[@test_index]["mappings"]["message"] == @target_mapping
    assert response.body[@test_index2]["mappings"]["comment"] == @target_mapping
  end

  test "put document with mapping should put document" do
    Index.create @test_url, @test_index, %{}
    Mapping.put @test_url, @test_index, "message", @mapping

    {:ok, response} = Document.index @test_url, @test_index, "message", 1, @data

    assert response.status_code == 201
    assert response.body["_id"] == "1"
    assert response.body["_index"] == @test_index
    assert response.body["_type"] == "message"
    assert response.body["created"] == true
  end
end

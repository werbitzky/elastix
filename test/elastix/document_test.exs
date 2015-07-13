defmodule ElastixDocumentTest do
  use ExUnit.Case
  alias Elastix.Index
  alias Elastix.Document

  setup do
    assert Index.delete("_all").status_code == 200
    
    :ok
  end
  
  test "make_path should make url from index name, type, url and query params" do
    assert Document.make_path("index_name", "tweet", 2, version: 34, ttl: "1d") == "/index_name/tweet/2?version=34&ttl=1d"
  end
  
  test "index should create and index with data" do
    data = %{
      user: "werbitzky",
      post_date: "2009-11-15T14:12:12",
      message: "trying out Elasticsearch"
    }
    
    response = Document.index "index_name", "message", 1, data
    
    assert response.status_code == 201
    assert response.body["_id"] == "1"
    assert response.body["_index"] == "index_name"
    assert response.body["_type"] == "message"
    assert response.body["created"] == true
  end
  
  test "get should return 404 if not index was created" do
    response = Document.get "index_name", "message", 1
    
    assert response.status_code == 404
  end
  
  test "get should return data with 200 after index" do
    data = %{
      user: "werbitzky",
      post_date: "2009-11-15T14:12:12",
      message: "trying out Elasticsearch"
    }
    
    Document.index "index_name", "message", 1, data
    response = Document.get "index_name", "message", 1
    body = response.body
    
    assert response.status_code == 200
    assert body["_source"]["user"] == "werbitzky"
    assert body["_source"]["post_date"] == "2009-11-15T14:12:12"
    assert body["_source"]["message"] == "trying out Elasticsearch"
  end
  
  test "delete should delete created index" do
    data = %{
      user: "werbitzky",
      post_date: "2009-11-15T14:12:12",
      message: "trying out Elasticsearch"
    }
    
    Document.index "index_name", "message", 1, data
    
    response = Document.get "index_name", "message", 1
    assert response.status_code == 200
    
    response = Document.delete "index_name", "message", 1
    assert response.status_code == 200
    
    response = Document.get "index_name", "message", 1
    assert response.status_code == 404
  end
end

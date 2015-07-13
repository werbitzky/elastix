defmodule ElastixSearchTest do
  use ExUnit.Case
  alias Elastix.Search
  alias Elastix.Index
  alias Elastix.Document

  setup do
    assert Index.delete("_all").status_code == 200
    
    :ok
  end
  
  test "make_path should make path from id and url" do
    path = Search.make_path("index_name", ["tweet", "product"], [ttl: "1d", timeout: 123])
    assert path == "/index_name/tweet,product/_search?ttl=1d&timeout=123"
  end
  
  test "search should return with status 200" do
    data = %{
      user: "werbitzky",
      post_date: "2009-11-15T14:12:12",
      message: "trying out Elasticsearch"
    }
        
    response = Document.index "index_name", "message", 1, data, [refresh: true]
    
    data = %{
      query: %{
        term: %{ user: "werbitzky" }
      }
    }
    response = Search.search "index_name", [], data
        
    assert response.status_code == 200
  end
end

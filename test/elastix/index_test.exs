defmodule ElastixIndexTest do
  use ExUnit.Case
  alias Elastix.Index

  setup do
    assert Index.delete("_all").status_code == 200
    
    :ok
  end
  
  test "exists? should return false if index is not created" do
    assert Index.exists?("index_name") == false
  end
  
  test "exists? should return true if index is created" do
    assert Index.create("index_name", %{}).status_code == 200
    assert Index.exists?("index_name") == true
  end
  
  test "make_path should make path from id and url" do
    assert Index.make_path("index_name") == "/index_name"
  end
  
  test "create then delete should respond with 200" do
    assert Index.create("index_name", %{}).status_code == 200
    assert Index.delete("index_name").status_code == 200
  end
  
  test "double create should respond with 400" do
    assert Index.create("index_name", %{}).status_code == 200
    assert Index.create("index_name", %{}).status_code == 400
    assert Index.delete("index_name").status_code == 200
  end
  
  test "get of uncreated index should respond with 404" do
    assert Index.get("index_name").status_code == 404
  end
  
  test "get of created index should respond with 200 and index data" do
    assert Index.create("index_name", %{}).status_code == 200
    
    index = Index.get("index_name")
    assert index.status_code == 200
    
    assert index.body["index_name"]
  end
end

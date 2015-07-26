defmodule Elastix.IndexTest do
  use ExUnit.Case
  alias Elastix.Index
  
  @test_index Elastix.config(:test_index)
  
  setup do
    Index.delete(@test_index)
    
    :ok
  end
  
  test "exists? should return false if index is not created" do
    assert Index.exists?(@test_index) == false
  end
  
  test "exists? should return true if index is created" do
    assert Index.create(@test_index, %{}).status_code == 200
    assert Index.exists?(@test_index) == true
  end
  
  test "make_path should make path from id and url" do
    assert Index.make_path(@test_index) == "/#{@test_index}"
  end
  
  test "create then delete should respond with 200" do
    assert Index.create(@test_index, %{}).status_code == 200
    assert Index.delete(@test_index).status_code == 200
  end
  
  test "double create should respond with 400" do
    assert Index.create(@test_index, %{}).status_code == 200
    assert Index.create(@test_index, %{}).status_code == 400
    assert Index.delete(@test_index).status_code == 200
  end
  
  test "get of uncreated index should respond with 404" do
    assert Index.get(@test_index).status_code == 404
  end
  
  test "get of created index should respond with 200 and index data" do
    assert Index.create(@test_index, %{}).status_code == 200
    
    index = Index.get(@test_index)
    assert index.status_code == 200
    
    assert index.body[@test_index]
  end
end

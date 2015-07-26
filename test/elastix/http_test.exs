defmodule Elastix.HTTPTest do
  use ExUnit.Case
  alias Elastix.HTTP

  test "process_url should concat with path" do
    assert HTTP.process_url("/some_path") == "http://127.0.0.1:9200/some_path"
  end
  
  test "get should respond with 200" do
    {_, response} = HTTP.get("", [])
    assert response.status_code == 200
  end
  
  test "post should respond with 400" do
    {_, response} = HTTP.post("", [])
    assert response.status_code == 400
  end
  
  test "put should respond with 400" do
    {_, response} = HTTP.put("", [])
    assert response.status_code == 400
  end
  
  test "delete should respond with 400" do
    {_, response} = HTTP.delete("", [])
    assert response.status_code == 400
  end
end

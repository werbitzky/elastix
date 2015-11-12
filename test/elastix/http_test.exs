defmodule Elastix.HTTPTest do
  use ExUnit.Case
  alias Elastix.HTTP

  @test_url Elastix.config(:test_url)
  @test_index Elastix.config(:test_index)

  test "process_url should concat with path" do
    assert HTTP.process_url("http://127.0.0.1:9200/some_path") == "http://127.0.0.1:9200/some_path"
  end

  test "get should respond with 200" do
    {_, response} = HTTP.get(@test_url, [])
    assert response.status_code == 200
  end

  test "post should respond with 400" do
    {_, response} = HTTP.post(@test_url, [])
    assert response.status_code == 400
  end

  test "put should respond with 400" do
    {_, response} = HTTP.put(@test_url, [])
    assert response.status_code == 400
  end

  test "delete should respond with 400" do
    {_, response} = HTTP.delete(@test_url, [])
    assert response.status_code == 400
  end
end

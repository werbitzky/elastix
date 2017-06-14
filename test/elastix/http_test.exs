defmodule Elastix.HTTPTest do
  use ExUnit.Case
  alias Elastix.HTTP

  @test_url Elastix.config(:test_url)

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

  test "process_response_body should parse the json body into a map" do
    body = "{\"some\":\"json\"}"
    assert HTTP.process_response_body(body) == %{"some" => "json"}
  end

  test "process_response_body returns the raw body if it cannot be parsed as json" do
    body = "no_json"
    assert HTTP.process_response_body(body) == body
  end

  test "process_response_body parsed the body into an atom key map if configured" do
    body = "{\"some\":\"json\"}"
    Application.put_env(:elastix, :poison_options, [keys: :atoms])
    assert HTTP.process_response_body(body) == %{some: "json"}
    Application.delete_env(:elastix, :poison_options)
  end

  test "adding custom headers" do
    Application.put_env(:elastix, :custom_headers, {__MODULE__, :add_custom_headers, [:foo]})
    Application.put_env(:elastix, :test_request_mfa, {__MODULE__, :return_headers, []})
    fake_resp = HTTP.request("GET", "#{@test_url}/_cluster/health", "", [{"yolo", "true"}])
    Application.delete_env(:elastix, :test_request_mfa)
    Application.delete_env(:elastix, :custom_headers)
    assert {"yolo", "true"} in fake_resp
    assert {"test", "pass"} in fake_resp
    assert {"Content-Type", "application/json; charset=UTF-8"} in fake_resp
  end

  # Test implementation of custom headers
  def add_custom_headers(request, :foo) do
    [{"test", "pass"} | request.headers]
  end

  # Skip actual http request so we can test what we sent to poison.
  def return_headers(_,_,_,_,headers,_,_,_,_) do
    headers
  end
end

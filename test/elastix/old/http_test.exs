defmodule Elastix.Old.HTTPTest do
  use ExUnit.Case
  alias Elastix.HTTP
  @old false

  @test_url Elastix.config(:test_url)

  setup_all do
    # Query the Elasticsearch instance to determine what version it is running
    # so we can use it in tests.
    {:ok, response} = HTTP.get(@test_url)
    {version, _rest} = Float.parse(response.body["version"]["number"])

    {:ok, version: version}
  end

  test "prepare_url/2 should concat url with path" do
    if @old do
    assert HTTP.prepare_url("http://127.0.0.1:9200/", "/some_path") ==
             "http://127.0.0.1:9200/some_path"
    end
  end

  test "prepare_url/2 should concat url with a list of path parts" do
    if @old do
    assert HTTP.prepare_url("http://127.0.0.1:9200/", ["/some/", "/path/"]) ==
             "http://127.0.0.1:9200/some/path"
    end
  end

  test "get should respond with 200" do
    {_, response} = HTTP.get(@test_url, [])
    assert response.status_code == 200
  end

  test "post should respond with 400", %{version: version} do
    {_, response} = HTTP.post(@test_url, [])
    if version >= 6.0 do
      assert response.status_code == 405
    else
      assert response.status_code == 400
    end
  end

  test "put should respond with 400", %{version: version} do
    {_, response} = HTTP.put(@test_url, [])
    if version >= 6.0 do
      assert response.status_code == 405
    else
      assert response.status_code == 400
    end
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
    Application.put_env(:elastix, :poison_options, keys: :atoms)
    assert HTTP.process_response_body(body) == %{some: "json"}
    Application.delete_env(:elastix, :poison_options)
  end

  test "adding custom headers" do
    Application.put_env(
      :elastix,
      :custom_headers,
      {__MODULE__, :add_custom_headers, [:foo]}
    )

    Application.put_env(:elastix, :test_request_mfa, {__MODULE__, :return_headers, []})

    fake_resp =
      HTTP.request("GET", "#{@test_url}/_cluster/health", "", [{"yolo", "true"}])

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
  def return_headers(_, %HTTPoison.Request{headers: headers}, _, _, _, _) do
    headers
  end
end

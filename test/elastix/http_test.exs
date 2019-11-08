defmodule Elastix.HTTPTest do
  @app :elastix

  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Elastix.HTTP

  @test_url Application.get_env(@app, :test_url)

  setup_all do
    # Query the Elasticsearch instance to determine what version it is running
    # so we can use it in tests.
    {:ok, response} = HTTP.get(@test_url)
    {version, _rest} = Float.parse(response.body["version"]["number"])

    {:ok, version: version}
  end

  test "get should respond with 200" do
    {:ok, response} = HTTP.get(@test_url, [])
    assert response.status_code == 200
  end

  test "make_url/3 handles all options" do
    url = "http://localhost:9200"
    assert HTTP.make_url(url, "foo") == "#{url}/foo"
    assert HTTP.make_url(url, ["foo", "bar"]) == "#{url}/foo/bar"
    assert HTTP.make_url(url, "/foo") == "#{url}/foo"
    assert HTTP.make_url(url, "/foo", this: true) == "#{url}/foo?this=true"
    assert HTTP.make_url(url, "/foo", %{biz: :baz, hello: 1}) == "#{url}/foo?biz=baz&hello=1"
  end

  test "add_content_type_header/1" do
    default_headers = [{"Content-Type", "application/json; charset=UTF-8"}]
    bulk_headers = [{"Content-Type", "application/x-ndjson"}]

    assert HTTP.add_content_type_header([]) == default_headers
    assert HTTP.add_content_type_header(bulk_headers) == bulk_headers
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

  describe "Environment specific tests" do
    setup do
      Application.put_env(:elastix, :poison_options, keys: :atoms)
      Application.put_env(:elastix, :json_options, keys: :atoms)

      on_exit(fn ->
        Application.delete_env(:elastix, :poison_options)
        Application.delete_env(:elastix, :json_options)
      end)

      :ok
    end

    test "using :poison_options logs a deprecation warning" do
      assert capture_log(fn ->
        body = "{\"some\":\"json\"}"
        Application.put_env(:elastix, :poison_options, keys: :atoms)
        %{some: "json"} = HTTP.process_response_body(body)
      end) =~ "Using :poison_options is deprecated and might not work in future releases; use :json_options instead"
    end

    @tag capture_log: true
    test "process_response_body parsed the body into an atom key map if configured" do
      body = "{\"some\":\"json\"}"
      Application.put_env(:elastix, :json_options, keys: :atoms)
      assert HTTP.process_response_body(body) == %{some: "json"}
      Application.delete_env(:elastix, :poison_options)
    end
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

  test "add_query_params/2" do
    params = %{foo: "bar", biz: 1}
    base = "http://localhost:9200/base"

    assert HTTP.add_query_params(base, nil) == base
    assert HTTP.add_query_params(base, %{}) == base
    assert HTTP.add_query_params(base, []) == base
    assert HTTP.add_query_params(base, foo: :bar, biz: 1) == "#{base}?foo=bar&biz=1"
    assert HTTP.add_query_params(base, params) == "#{base}?biz=1&foo=bar"
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

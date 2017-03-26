defmodule Elastix.HTTPTest do
  use ExUnit.Case
  alias Elastix.HTTP

  @test_url Elastix.config(:test_url)

  setup do
    # reset application configs
    Application.put_env(:elastix, :shield, false)
    Application.put_env(:elastix, :aws_es, nil)

    :ok
  end

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

  describe "process_request_headers" do
    test "without authorization header" do
      headers = [{:"Content-Type", "application/json; charset=UTF-8"}]
      assert HTTP.process_request_headers([]) == headers
    end

    test "shield authorization header" do
      # update the elastix configs to use shield
      Application.put_env(:elastix, :shield, true)
      Application.put_env(:elastix, :username, "username")
      Application.put_env(:elastix, :password, "password")

      auth_token = Base.encode64("#{Elastix.config(:username)}:#{Elastix.config(:password)}")

      # generate the auth headers to test against
      headers = [
        {:"Authorization", "Basic " <> auth_token},
        {:"Content-Type", "application/json; charset=UTF-8"}
      ]

      assert HTTP.process_request_headers([]) == headers
    end

    test "aws_es signed authorization header" do
      url  = "https://es.amazonaws.com/"
      time = DateTime.utc_now() |> DateTime.to_naive()

      # update the elastix configs to use aws_es
      Application.put_env(:elastix, :aws_es, [region: "us-west-2", access_key: "key", secret_key: "secret"])

      # https://github.com/bryanjos/aws_auth
      signed_request = AWSAuth.sign_authorization_header("key", "secret", "GET", url, "us-west-2", "es", %{"Content-Type" => "application/json; charset=UTF-8","x-amz-date" => AWSAuth.Utils.format_time(time)}, "body", time)

      # generate the signed auth headers to test against
      headers = [
        {:"x-amz-content-sha256", AWSAuth.Utils.hash_sha256("body")},
        {:"x-amz-date", AWSAuth.Utils.format_time(time)},
        {:"host", "es.amazonaws.com"},
        {:"Content-Type", "application/json; charset=UTF-8"}
      ]

      headers_with_auth = [{:"Authorization", signed_request}] ++ headers

      assert HTTP.process_request_headers(headers, {:get, url, "body"}) == headers_with_auth
    end
  end
end

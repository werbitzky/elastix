defmodule Elastix.IndexTest do
  use ExUnit.Case
  alias Elastix.Index

  @test_url Elastix.config(:test_url)
  @test_index Elastix.config(:test_index)

  setup do
    Index.delete(@test_url, @test_index)

    :ok
  end

  test "exists? should return false if index is not created" do
    assert {:ok, false} == Index.exists?(@test_url, @test_index)
  end

  test "exists? should return true if index is created" do
    assert {:ok, %{status_code: 200}} = Index.create(@test_url, @test_index, %{})
    assert {:ok, true} == Index.exists?(@test_url, @test_index)
  end

  test "make_path should make path from id and url" do
    assert Index.make_path(@test_index) == "/#{@test_index}"
  end

  test "create then delete should respond with 200" do
    assert {:ok, %{status_code: 200}} = Index.create(@test_url, @test_index, %{})
    assert {:ok, %{status_code: 200}} = Index.delete(@test_url, @test_index)
  end

  test "double create should respond with 400" do
    assert {:ok, %{status_code: 200}} = Index.create(@test_url, @test_index, %{})
    assert {:ok, %{status_code: 400}} = Index.create(@test_url, @test_index, %{})
    assert {:ok, %{status_code: 200}} = Index.delete(@test_url, @test_index)
  end

  test "get of uncreated index should respond with 404" do
    assert {:ok, %{status_code: 404}} = Index.get(@test_url, @test_index)
  end

  test "get of created index should respond with 200 and index data" do
    assert {:ok, %{status_code: 200}} = Index.create(@test_url, @test_index, %{})

    {:ok, index} = Index.get(@test_url, @test_index)
    assert index.status_code == 200

    assert index.body[@test_index]
  end

  test "refresh of uncreated index should respond with 404" do
    assert {:ok, %{status_code: 404}} = Index.refresh(@test_url, @test_index)
  end

  test "refresh of existing index should respond with 200" do
    Index.create(@test_url, @test_index, %{})
    assert {:ok, %{status_code: 200}} = Index.refresh(@test_url, @test_index)
  end
end

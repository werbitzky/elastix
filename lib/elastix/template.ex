defmodule Elastix.Template do
  @moduledoc """
  Index templates define settings and mappings that you can automatically apply
  when creating new indices. Elasticsearch applies templates to new indices
  based on an index pattern that matches the index name.

  [Elastic documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html)
  """
  alias Elastix.{HTTP, JSON}

  @doc """
  Create a new index template.

  ## Examples

      iex> template = %{
         "index_patterns" => "logstash-*",
         "mappings" => %{
           "dynamic_templates" => [
             %{
               "message_field" => %{
                 "mapping" => %{"norms" => false, "type" => "text"},
                 "match_mapping_type" => "string",
                 "path_match" => "message"
               }
             },
             %{
               "string_fields" => %{
                 "mapping" => %{
                   "fields" => %{
                     "keyword" => %{"ignore_above" => 256, "type" => "keyword"}
                   },
                   "norms" => false,
                   "type" => "text"
                 },
                 "match" => "*",
                 "match_mapping_type" => "string"
               }
             }
           ],
           "properties" => %{
             "@timestamp" => %{"type" => "date"},
             "@version" => %{"type" => "keyword"},
             "geoip" => %{
               "dynamic" => true,
               "properties" => %{
                 "ip" => %{"type" => "ip"},
                 "latitude" => %{"type" => "half_float"},
                 "location" => %{"type" => "geo_point"},
                 "longitude" => %{"type" => "half_float"}
               }
             }
           }
         },
         "settings" => %{"index.refresh_interval" => "5s", "number_of_shards" => 1},
         "version" => 60001
       }
      iex> Elastix.Template.put("http://localhost:9200", "logstash", template)
      {:ok, %HTTPoison.Response{...}}
  """
  @spec put(binary, binary, binary | term, Keyword.t) :: HTTP.resp
  def put(elastic_url, template, data, query_params \\ [])
  def put(elastic_url, template, data, query_params) when is_binary(data) do
    url = HTTP.make_url(elastic_url, make_path(template), query_params)
    HTTP.put(url, data)
  end
  def put(elastic_url, template, data, query_params) do
    put(elastic_url, template, JSON.encode!(data), query_params)
  end

  @doc """
  Determine if an index template has alreay been registered.

  ## Examples

      iex> Elastix.Template.exists?("http://localhost:9200", "logstash")
      {:ok, false}

      iex> Elastix.Template.exists?("http://localhost:9200", "logstash")
      {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}}
  """
  @spec exists?(binary, binary, Keyword.t) :: {:ok, boolean} | {:error, HTTPoison.Error.t}
  def exists?(elastic_url, template, query_params \\ []) do
    url = HTTP.make_url(elastic_url, make_path(template), query_params)

    case HTTP.head(url) do
      {:ok, %{status_code: code}} when code >= 200 and code <= 299 ->
        {:ok, true}
      {:ok, _} ->
        {:ok, false}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get info on an index template.

  ## Examples

      iex> Elastix.Template.get("http://localhost:9200", "logstash")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec get(binary, binary, Keyword.t) :: HTTP.resp
  def get(elastic_url, template, query_params \\ []) do
    url = HTTP.make_url(elastic_url, make_path(template), query_params)
    HTTP.get(url)
  end

  @doc """
  Delete an index template.

  [Elasticsearch docs](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-delete-template.html)
  #
  ## Examples

      iex> Elastix.Template.get("http://localhost:9200", "logstash")
      {:ok, %HTTPoison.Response{...}}
  """
  @spec delete(binary, binary, Keyword.t) :: HTTP.resp
  def delete(elastic_url, template, query_params \\ []) do
    url = HTTP.make_url(elastic_url, make_path(template), query_params)
    HTTP.delete(url)
  end

  @doc false
  # Convert params into path
  @spec make_path(binary) :: binary
  def make_path(template), do: "/_template/#{template}"

end

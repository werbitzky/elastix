defmodule Elastix.TemplateTest do

  use ExUnit.Case

  alias Elastix.Template

  # @test_url Elastix.config(:test_url)

  @test_url Elastix.config(:test_url)
  @template "elastix_test"

  setup do
    on_exit(fn ->
      Template.delete(@test_url, @template)
    end)

    template = """
    {
      "template" : "logstash-*",
      "version" : 60001,
      "settings" : {
        "index.refresh_interval" : "5s"
      },
      "mappings" : {
        "_default_" : {
          "dynamic_templates" : [ {
            "message_field" : {
              "path_match" : "message",
              "match_mapping_type" : "string",
              "mapping" : {
                "type" : "text",
                "norms" : false
              }
            }
          }, {
            "string_fields" : {
              "match" : "*",
              "match_mapping_type" : "string",
              "mapping" : {
                "type" : "text", "norms" : false,
                "fields" : {
                  "keyword" : { "type": "keyword", "ignore_above": 256 }
                }
              }
            }
          } ],
          "properties" : {
            "@timestamp": { "type": "date"},
            "@version": { "type": "keyword"},
            "geoip"  : {
              "dynamic": true,
              "properties" : {
                "ip": { "type": "ip" },
                "location" : { "type" : "geo_point" },
                "latitude" : { "type" : "half_float" },
                "longitude" : { "type" : "half_float" }
              }
            }
          }
        }
      }
    }
    """

    {:ok, template_data: template}
  end

  test "make_path/1 makes path from params" do
    assert Template.make_path("foo") == "/_template/foo"
  end

  test "creates template", %{template_data: template_data} do
    {:ok, response} = Template.put(@test_url, @template, template_data)
    assert response.status_code == 200
  end

  test "gets template info", %{template_data: template_data} do
    {:ok, response} = Template.put(@test_url, @template, template_data)
    assert response.status_code == 200

    {:ok, response} = Template.get(@test_url, @template)
    assert response.status_code == 200
    assert response.body[@template]["index_patterns"] == ["logstash-*"]
  end

  test "checks if template exists", %{template_data: template_data} do
    assert {:ok, false} == Template.exists?(@test_url, @template)

    {:ok, response} = Template.put(@test_url, @template, template_data)
    assert response.status_code == 200

    assert {:ok, true} == Template.exists?(@test_url, @template)
  end

end


# frozen_string_literal: true

require_relative "test_helper"

# The decisions every exporter must share: is this request JSON, how does a
# nested query flatten, what goes on the wire as the body.
class PayloadRendererTest < Minitest::Test
  include Reqcord::TestHelpers

  Payload = Reqcord::Renderers::Payload

  def request(**attributes)
    Reqcord::RequestExample.new(**{ method: "POST", path: "/api/v1/customers" }.merge(attributes))
  end

  def test_json_is_recognised_from_the_content_type
    assert Payload.json?(request(content_type: "application/json"))
    assert Payload.json?(request(content_type: "application/vnd.api+json"))
    refute Payload.json?(request(content_type: "application/x-www-form-urlencoded"))
  end

  def test_json_is_recognised_from_the_header_when_the_content_type_is_missing
    assert Payload.json?(request(headers: { "content-type" => "application/json" }))
    refute Payload.json?(request)
  end

  def test_nested_query_flattens_with_rails_bracket_notation
    pairs = Payload.flatten_query("filter" => { "status" => "active" }, "ids" => [1, 2], "page" => 2)

    assert_equal [["filter[status]", "active"], ["ids[]", 1], ["ids[]", 2], ["page", 2]], pairs
  end

  def test_arrays_of_objects_flatten_with_an_index_less_key
    pairs = Payload.flatten_query("items" => [{ "sku" => "X1", "qty" => 2 }])

    assert_equal [["items[][sku]", "X1"], ["items[][qty]", 2]], pairs
  end

  def test_path_with_query_appends_an_encoded_query_string
    subject = request(method: "GET", query_params: { "q" => "john doe", "filter" => { "status" => "active" } })

    assert_equal "/api/v1/customers?q=john+doe&filter%5Bstatus%5D=active", Payload.path_with_query(subject)
    assert_equal "/api/v1/customers", Payload.path_with_query(request(method: "GET"))
  end

  def test_json_bodies_are_pretty_printed
    raw = Payload.raw_body(request(content_type: "application/json", body: { "customer" => { "name" => "Ada" } }))

    assert_equal JSON.pretty_generate("customer" => { "name" => "Ada" }), raw
  end

  def test_form_bodies_are_url_encoded
    raw = Payload.raw_body(request(content_type: "application/x-www-form-urlencoded", body: { "customer" => { "name" => "Ada Lovelace" } }))

    assert_equal "customer%5Bname%5D=Ada+Lovelace", raw
  end

  def test_string_bodies_pass_through
    assert_equal "plain text", Payload.raw_body(request(content_type: "text/plain", body: "plain text"))
  end

  def test_form_pairs_are_empty_for_non_hash_bodies
    assert_empty Payload.form_pairs(request(body: "raw"))
    assert_empty Payload.form_pairs(request)
  end
end

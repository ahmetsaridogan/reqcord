# frozen_string_literal: true

require_relative "test_helper"

class CurlRendererTest < Minitest::Test
  include Reqcord::TestHelpers

  def render(**attributes)
    request = Reqcord::RequestExample.new(
      **{ method: "POST", path: "/api/v1/customers" }.merge(attributes)
    )

    Reqcord::Renderers::Curl.call(request, base_url: "http://localhost:3000")
  end

  def test_generates_curl_request
    curl = render(
      headers: { "Authorization" => "Bearer {{token}}", "Content-Type" => "application/json" },
      body: { customer: { name: "Ahmet" } }
    )

    assert_includes curl, "curl --request POST"
    assert_includes curl, '--url "http://localhost:3000/api/v1/customers"'
    assert_includes curl, "Authorization: Bearer {{token}}"
    assert_includes curl, '"name": "Ahmet"'
    refute curl.end_with?("\\")
  end

  def test_flattens_nested_query_parameters
    curl = render(method: "GET", query_params: { "filter" => { "status" => "active" }, "ids" => [1, 2] })

    assert_includes curl, "filter%5Bstatus%5D=active"
    assert_includes curl, "ids%5B%5D=1&ids%5B%5D=2"
  end

  def test_escapes_single_quotes_so_the_command_still_runs
    curl = render(body: { "name" => "O'Brien" }, content_type: "application/json")

    assert_includes curl, %q(O'"'"'Brien)
  end

  # A form body never carries a raw quote: it is percent-encoded instead.
  def test_form_bodies_percent_encode_quotes
    curl = render(body: { "name" => "O'Brien" }, content_type: "application/x-www-form-urlencoded")

    assert_includes curl, "name=O%27Brien"
    refute_includes curl, "O'Brien"
  end

  def test_escapes_backslashes_and_quotes_in_headers
    curl = render(headers: { "X-Note" => 'a\b"c' })

    assert_includes curl, '--header "X-Note: a\\\\b\"c"'
  end

  def test_omits_data_when_there_is_no_body
    refute_includes render(method: "GET", path: "/api/v1/customers/42"), "--data"
  end

  def test_trailing_slash_in_base_url_is_dropped
    request = Reqcord::RequestExample.new(method: "GET", path: "/api/v1/customers")
    curl = Reqcord::Renderers::Curl.call(request, base_url: "http://localhost:3000/")

    assert_includes curl, '--url "http://localhost:3000/api/v1/customers"'
  end
end

# Regression: the canonical cURL payload must stay exactly the successful
# test case payload instead of being inferred from schemas or error cases.
class CurlSuccessfulPayloadTest < Minitest::Test
  def test_successful_payload_is_rendered_verbatim
    request = Reqcord::RequestExample.new(
      method: "POST",
      path: "/api/v2/customers",
      response_status: 201,
      headers: { "Content-Type" => "application/json" },
      content_type: "application/json",
      body: {
        "customer" => {
          "name" => "John Doe",
          "email" => "john@example.com",
          "settings" => { "notifications" => true },
          "tags" => ["vip", "beta"]
        }
      }
    )

    curl = Reqcord::Renderers::Curl.call(request, base_url: "http://localhost:3000")

    assert_includes curl, '"email": "john@example.com"'
    assert_includes curl, '"notifications": true'
    assert_includes curl, '"vip"'
    assert_includes curl, '"beta"'
  end
end

class CurlFormPayloadTest < Minitest::Test
  def test_form_payload_is_urlencoded_instead_of_inventing_json
    request = Reqcord::RequestExample.new(
      method: "POST",
      path: "/api/v2/customers",
      content_type: "application/x-www-form-urlencoded",
      headers: { "Content-Type" => "application/x-www-form-urlencoded" },
      body: { "customer" => { "name" => "John Doe", "active" => true } }
    )

    curl = Reqcord::Renderers::Curl.call(request, base_url: "http://localhost:3000")

    assert_includes curl, "customer%5Bname%5D=John+Doe"
    assert_includes curl, "customer%5Bactive%5D=true"
    refute_includes curl, '"customer"'
  end
end

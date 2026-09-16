# frozen_string_literal: true

require_relative "test_helper"

class OpenapiExporterTest < Minitest::Test
  include Reqcord::TestHelpers

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE
  end

  def export(root, exchanges = default_exchanges, routes: customer_routes)
    configuration = configuration_for(root)

    dataset = Reqcord::Generator
              .new(resources: [], version: nil, configuration: configuration)
              .build_dataset(routes, exchanges)

    files = Reqcord::Exporters::Openapi.call(
      dataset: dataset,
      output_dir: configuration.output_directory,
      configuration: configuration
    )

    assert_equal 1, files.size

    [JSON.parse(File.read(files.first)), files.first]
  end

  def default_exchanges
    [
      exchange("request" => { "body" => { "customer" => { "name" => "John Doe", "email" => "john@example.com", "status" => "active", "tags" => %w[vip] } } }),
      exchange("request" => { "body" => { "customer" => { "name" => "Jane Roe", "email" => "jane@example.com", "status" => "passive" } } }),
      exchange("response" => { "status" => 401, "body" => { "error" => "Unauthorized" } }, "request" => { "headers" => { "Content-Type" => "application/json" } }),
      exchange(
        "request" => { "method" => "GET", "path" => "/api/v2/customers/42", "body" => nil, "path_params" => { "id" => "42" }, "query_params" => { "expand" => "orders", "filter" => { "status" => "active" } } },
        "response" => { "status" => 200, "body" => { "id" => 42, "orders" => [{ "number" => "ORD-1" }] } }
      )
    ]
  end

  def test_writes_a_3_1_document_with_servers_and_tags
    Dir.mktmpdir do |root|
      document, path = export(root)

      assert_equal File.join(root, "docs", "api", "openapi", "openapi.json"), path
      assert_equal "3.1.0", document["openapi"]
      assert_equal "v2", document.dig("info", "version")
      assert_equal [{ "url" => "http://localhost:3000" }], document["servers"]
      assert_equal [{ "name" => "Customers", "description" => "api/v2/customers" }], document["tags"]
    end
  end

  def test_rails_patterns_become_openapi_paths
    Dir.mktmpdir do |root|
      document, = export(root)

      assert_equal ["/api/v2/customers", "/api/v2/customers/{id}"], document["paths"].keys.sort
      assert_equal %w[post], document["paths"]["/api/v2/customers"].keys
      assert_equal "post_api_v2_customers", document.dig("paths", "/api/v2/customers", "post", "operationId")
    end
  end

  def test_request_body_schema_is_unflattened_with_required_and_enum
    Dir.mktmpdir do |root|
      document, = export(root)
      body = document.dig("paths", "/api/v2/customers", "post", "requestBody")
      schema = body.dig("content", "application/json", "schema")
      customer = schema.dig("properties", "customer")

      assert body["required"]
      assert_equal "object", schema["type"]
      assert_equal ["customer"], schema["required"]
      assert_equal %w[email name status], customer["required"].sort
      assert_equal({ "type" => "string", "enum" => %w[active passive], "example" => "active" }, customer.dig("properties", "status"))
      assert_equal "array", customer.dig("properties", "tags", "type")
      assert_equal "string", customer.dig("properties", "tags", "items", "type")
      refute_includes customer["required"], "tags"
      assert_equal "john@example.com", body.dig("content", "application/json", "example", "customer", "email")
    end
  end

  def test_path_and_query_parameters
    Dir.mktmpdir do |root|
      document, = export(root)
      parameters = document.dig("paths", "/api/v2/customers/{id}", "get", "parameters")
      by_name = parameters.to_h { |parameter| [parameter["name"], parameter] }

      assert_equal "path", by_name["id"]["in"]
      assert by_name["id"]["required"]
      assert_equal "42", by_name["id"]["example"]
      assert_equal "query", by_name["expand"]["in"]
      assert by_name["expand"]["required"]
      # Nested query params keep Rails' bracket notation.
      assert_equal "query", by_name["filter[status]"]["in"]
    end
  end

  def test_every_captured_status_is_a_response_with_schema_and_example
    Dir.mktmpdir do |root|
      document, = export(root)
      responses = document.dig("paths", "/api/v2/customers", "post", "responses")

      assert_equal %w[201 401], responses.keys.sort
      assert_equal "Created", responses.dig("201", "description")
      assert_equal "integer", responses.dig("201", "content", "application/json", "schema", "properties", "id", "type")
      assert_equal({ "error" => "Unauthorized" }, responses.dig("401", "content", "application/json", "example"))

      show = document.dig("paths", "/api/v2/customers/{id}", "get", "responses", "200", "content", "application/json", "schema")
      assert_equal "array", show.dig("properties", "orders", "type")
      assert_equal "string", show.dig("properties", "orders", "items", "properties", "number", "type")
    end
  end

  def test_bearer_security_comes_from_the_sanitized_authorization_header
    Dir.mktmpdir do |root|
      document, = export(root)

      assert_equal({ "type" => "http", "scheme" => "bearer" }, document.dig("components", "securitySchemes", "bearerAuth"))
      assert_equal [{ "bearerAuth" => [] }], document.dig("paths", "/api/v2/customers", "post", "security")
    end
  end

  def test_public_endpoints_carry_no_security_and_form_bodies_are_urlencoded
    Dir.mktmpdir do |root|
      form = exchange(
        "request" => { "headers" => { "Content-Type" => "application/x-www-form-urlencoded" }, "content_type" => "application/x-www-form-urlencoded",
                       "body" => { "customer" => { "name" => "Ada" } } }
      )
      form["request"]["headers"].delete("Authorization")
      document, = export(root, [form])
      operation = document.dig("paths", "/api/v2/customers", "post")

      refute operation.key?("security")
      refute document.key?("components")
      assert operation.dig("requestBody", "content").key?("application/x-www-form-urlencoded")
    end
  end

  def test_optional_segments_become_two_paths
    Dir.mktmpdir do |root|
      exchanges = [
        exchange("request" => { "method" => "GET", "path" => "/items", "body" => nil }, "response" => { "status" => 200, "body" => [{ "id" => 1 }] })
      ]
      document, = export(root, exchanges, routes: mixed_routes(prefix: "/items"))

      assert_equal ["/items", "/items/{id}"], document["paths"].keys.sort
      assert_equal "array", document.dig("paths", "/items", "get", "responses", "200", "content", "application/json", "schema", "type")
    end
  end

  def test_credentials_never_reach_the_document
    Dir.mktmpdir do |root|
      _, path = export(root)

      refute_includes File.read(path), "eyJhbGciOi"
    end
  end
end

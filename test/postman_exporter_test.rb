# frozen_string_literal: true

require_relative "test_helper"

class PostmanExporterTest < Minitest::Test
  include Reqcord::TestHelpers

  SCHEMA = File.expand_path("fixtures/postman_collection_v2.1.0.json", __dir__)

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE
  end

  def export(root)
    configuration = configuration_for(root)

    exchanges = [
      exchange,
      exchange("response" => { "status" => 401, "body" => { "error" => "Unauthorized" } }, "request" => { "headers" => { "Content-Type" => "application/json" } }),
      exchange(
        "request" => { "body" => { "customer" => { "email" => "taken@example.com" } } },
        "response" => { "status" => 422, "body" => { "errors" => { "email" => ["has already been taken"] } } }
      ),
      exchange(
        "request" => { "method" => "GET", "path" => "/api/v2/customers/42", "body" => nil, "path_params" => { "id" => "42" }, "query_params" => { "expand" => "orders" } },
        "response" => { "status" => 200, "body" => { "id" => 42 } }
      ),
      exchange(
        "request" => {
          "method" => "GET", "path" => "/api/v2/customers", "body" => nil,
          "headers" => { "Content-Type" => "application/x-www-form-urlencoded" }, "content_type" => "application/x-www-form-urlencoded"
        },
        "response" => { "status" => 200, "body" => [{ "id" => 42 }] }
      )
    ]

    dataset = Reqcord::Generator
              .new(resources: [], version: nil, configuration: configuration)
              .build_dataset(customer_routes, exchanges)

    files = Reqcord::Exporters::Postman.call(
      dataset: dataset,
      output_dir: configuration.output_directory,
      configuration: configuration
    )

    [JSON.parse(File.read(files.single)), files.single]
  end

  def requests(items)
    items.flat_map { |item| item.key?("item") ? requests(item["item"]) : [item] }
  end

  def test_writes_one_collection_file
    Dir.mktmpdir do |root|
      collection, path = export(root)

      assert_equal File.join(root, "docs", "api", "postman", "collection.json"), path
      assert_equal Reqcord::Exporters::Postman::SCHEMA_URL, collection.dig("info", "schema")
      assert_equal "#{File.basename(root)} API", collection.dig("info", "name")
    end
  end

  def test_folders_follow_the_controller_namespaces
    Dir.mktmpdir do |root|
      collection, = export(root)

      api = collection["item"].single
      assert_equal "Api", api["name"]
      v2 = api["item"].single
      assert_equal "V2", v2["name"]
      customers = v2["item"].single
      assert_equal "Customers", customers["name"]
      assert_equal ["List Customers", "Create Customer", "Get Customer"], customers["item"].map { |item| item["name"] }
    end
  end

  def test_the_request_is_the_successful_captured_example
    Dir.mktmpdir do |root|
      collection, = export(root)
      create = requests(collection["item"]).find { |item| item["name"] == "Create Customer" }
      request = create["request"]

      assert_equal "POST", request["method"]
      assert_equal "{{base_url}}/api/v2/customers", request.dig("url", "raw")
      assert_equal %w[api v2 customers], request.dig("url", "path")
      assert_equal "raw", request.dig("body", "mode")
      assert_equal "json", request.dig("body", "options", "raw", "language")
      assert_includes request.dig("body", "raw"), "john@example.com"
      refute_includes request.dig("body", "raw"), "taken@example.com"
      assert_includes request["description"], "api/v2/customers#create"
    end
  end

  def test_the_bearer_credential_lives_on_the_collection
    Dir.mktmpdir do |root|
      collection, = export(root)

      assert_equal "bearer", collection.dig("auth", "type")
      assert_equal "{{token}}", collection.dig("auth", "bearer", 0, "value")

      create = requests(collection["item"]).find { |item| item["name"] == "Create Customer" }

      refute create["request"]["header"].any? { |header| header["key"] == "Authorization" }
      assert create["request"]["header"].any? { |header| header["key"] == "X-Account-Id" }
      refute create["request"].key?("auth")

      unauthorized = create["response"].find { |response| response["code"] == 401 }

      assert_equal "noauth", unauthorized.dig("originalRequest", "auth", "type")
    end
  end

  def test_every_captured_status_is_a_saved_example
    Dir.mktmpdir do |root|
      collection, = export(root)
      create = requests(collection["item"]).find { |item| item["name"] == "Create Customer" }

      assert_equal [201, 401, 422], create["response"].map { |response| response["code"] }
      assert_equal "201 Created", create["response"].first["name"]
      assert_includes create["response"].last["body"], "has already been taken"
    end
  end

  def test_query_parameters_and_variables_are_declared
    Dir.mktmpdir do |root|
      collection, = export(root)
      show = requests(collection["item"]).find { |item| item["name"] == "Get Customer" }

      assert_equal "{{base_url}}/api/v2/customers/42?expand=orders", show.dig("request", "url", "raw")
      assert_equal [{ "key" => "expand", "value" => "orders" }], show.dig("request", "url", "query")

      variables = collection["variable"].to_h { |variable| [variable["key"], variable["value"]] }

      assert_equal "http://localhost:3000", variables["base_url"]
      assert variables.key?("token")
      assert variables.key?("api_key")
    end
  end

  def test_credentials_never_reach_the_collection
    Dir.mktmpdir do |root|
      _, path = export(root)

      refute_includes File.read(path), "eyJhbGciOi"
    end
  end

  def test_validates_against_the_vendored_schema
    begin
      require "json-schema"
    rescue LoadError
      skip "json-schema gem is not installed"
    end

    Dir.mktmpdir do |root|
      collection, = export(root)
      schema = JSON.parse(File.read(SCHEMA))

      assert_empty JSON::Validator.fully_validate(schema, collection)
    end
  end
end

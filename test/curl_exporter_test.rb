# frozen_string_literal: true

require_relative "test_helper"

class CurlExporterTest < Minitest::Test
  include Reqcord::TestHelpers

  def test_writes_successful_captured_payload
    Dir.mktmpdir do |root|
      endpoint = Reqcord::Endpoint.new(
        method: "POST",
        path: "/api/v2/customers",
        controller: "api/v2/customers",
        action: "create"
      )

      endpoint.add_request_example(
        Reqcord::RequestExample.new(
          method: "POST",
          path: "/api/v2/customers",
          response_status: 422,
          body: { "customer" => { "email" => "taken@example.com" } }
        )
      )

      endpoint.add_request_example(
        Reqcord::RequestExample.new(
          method: "POST",
          path: "/api/v2/customers",
          response_status: 201,
          headers: { "Content-Type" => "application/json" },
          content_type: "application/json",
          body: { "customer" => { "email" => "john@example.com", "name" => "John Doe" } }
        )
      )

      dataset = Reqcord::Dataset.new(endpoints: [endpoint])
      configuration = configuration_for(root, "exporters:\n  - curl\n")

      Reqcord::Exporters::Curl.call(
        dataset: dataset,
        output_dir: root,
        configuration: configuration
      )

      script = File.read(File.join(root, "curl", "api", "v2", "customers", "create.sh"))

      assert_includes script, '"email": "john@example.com"'
      refute_includes script, "taken@example.com"
      assert_includes script, "curl --request POST"
    end
  end
  def test_does_not_write_curl_for_error_only_endpoint
    Dir.mktmpdir do |root|
      endpoint = Reqcord::Endpoint.new(
        method: "POST",
        path: "/api/v2/customers",
        controller: "api/v2/customers",
        action: "create"
      )

      endpoint.add_request_example(
        Reqcord::RequestExample.new(
          method: "POST",
          path: "/api/v2/customers",
          response_status: 422,
          body: { "customer" => { "email" => "taken@example.com" } }
        )
      )

      dataset = Reqcord::Dataset.new(endpoints: [endpoint])
      configuration = configuration_for(root, "exporters:\n  - curl\n")

      files = Reqcord::Exporters::Curl.call(
        dataset: dataset,
        output_dir: root,
        configuration: configuration
      )

      assert_empty files
      refute File.exist?(File.join(root, "curl", "api", "v2", "customers", "create.sh"))
    end
  end

end

# frozen_string_literal: true

require_relative "test_helper"
require "rack/mock"

class WebTest < Minitest::Test
  include Reqcord::TestHelpers

  def with_output
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "openapi"))
      FileUtils.mkdir_p(File.join(root, "api", "v1", "customers"))
      File.write(File.join(root, "openapi", "openapi.json"), JSON.generate("openapi" => "3.1.0", "paths" => {}))
      File.write(File.join(root, "dataset.json"), JSON.generate("schema_version" => 2))
      File.write(File.join(root, "api", "v1", "customers", "create.md"), "# Create Customer\n")

      yield root, Rack::MockRequest.new(Reqcord::Web.new(root: root))
    end
  end

  def test_the_index_renders_the_openapi_document_with_scalar
    with_output do |_root, request|
      response = request.get("/", "SCRIPT_NAME" => "/api-docs")

      assert_equal 200, response.status
      assert_includes response.headers["content-type"], "text/html"
      assert_includes response.body, %(data-url="/api-docs/openapi/openapi.json")
      assert_includes response.body, Reqcord::Web::SCALAR_SCRIPT
    end
  end

  def test_generated_files_are_served_with_their_content_type
    with_output do |_root, request|
      openapi = request.get("/openapi/openapi.json")
      page = request.get("/api/v1/customers/create.md")

      assert_equal 200, openapi.status
      assert_equal "application/json", openapi.headers["content-type"]
      assert_equal "3.1.0", JSON.parse(openapi.body)["openapi"]
      assert_includes page.headers["content-type"], "text/markdown"
      assert_equal "# Create Customer\n", page.body
    end
  end

  def test_nothing_outside_the_output_directory_is_served
    with_output do |_root, request|
      assert_equal 404, request.get("/../Gemfile").status
      assert_equal 404, request.get("/%2e%2e/Gemfile").status
      assert_equal 404, request.get("/missing.json").status
      assert_equal 404, request.get("/api/v1/customers").status
    end
  end

  def test_before_the_first_generate_the_index_explains_what_to_run
    Dir.mktmpdir do |root|
      response = Rack::MockRequest.new(Reqcord::Web.new(root: root)).get("/", "SCRIPT_NAME" => "/api-docs")

      assert_equal 200, response.status
      assert_includes response.body, "bin/rails reqcord:generate"
      assert_includes response.body, %(href="/api-docs/dataset.json")
      refute_includes response.body, Reqcord::Web::SCALAR_SCRIPT
    end
  end

  def test_the_class_itself_is_a_rack_app_for_mount
    assert_respond_to Reqcord::Web, :call
  end
end

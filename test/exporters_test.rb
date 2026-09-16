# frozen_string_literal: true

require_relative "test_helper"

class ExportersTest < Minitest::Test
  include Reqcord::TestHelpers

  def test_markdown_registers_itself
    assert Reqcord::Exporters.registered?("markdown")
    assert_equal Reqcord::Exporters::Markdown, Reqcord::Exporters.fetch("markdown")
    assert_includes Reqcord::Exporters.names, "markdown"
  end

  def test_an_unknown_name_names_the_alternatives
    error = assert_raises(Reqcord::ConfigurationError) { Reqcord::Exporters.fetch("graphql") }

    assert_match(/unknown exporter "graphql"/, error.message)
    assert_match(/markdown/, error.message)
  end

  def test_registering_makes_an_exporter_usable
    fake = Class.new
    Reqcord::Exporters.register("fake", fake)

    assert_equal fake, Reqcord::Exporters.fetch("fake")
  ensure
    Reqcord::Exporters.registry.delete("fake")
  end
end

class CurlExporterRegistrationTest < Minitest::Test
  def test_curl_registers_itself
    assert Reqcord::Exporters.registered?("curl")
    assert_equal Reqcord::Exporters::Curl, Reqcord::Exporters.fetch("curl")
  end
end

class PostmanExporterRegistrationTest < Minitest::Test
  def test_postman_registers_itself
    assert Reqcord::Exporters.registered?("postman")
    assert_equal Reqcord::Exporters::Postman, Reqcord::Exporters.fetch("postman")
    assert_equal %w[curl markdown openapi postman], Reqcord::Exporters.names
  end
end

class OpenapiExporterRegistrationTest < Minitest::Test
  def test_openapi_registers_itself
    assert Reqcord::Exporters.registered?("openapi")
    assert_equal Reqcord::Exporters::Openapi, Reqcord::Exporters.fetch("openapi")
  end
end

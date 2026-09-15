# frozen_string_literal: true

require_relative "test_helper"

class ConfigurationTest < Minitest::Test
  include Reqcord::TestHelpers

  def test_loads_default_configuration
    Dir.mktmpdir do |directory|
      config = Reqcord::Configuration.load(root: directory)

      assert_equal "minitest", config.test_framework
      assert_equal "/api", config.route_prefix
      assert_equal %w[curl markdown postman], config.exporters
      assert_equal "http://localhost:3000", config.base_url
      assert_equal File.join(directory, "docs/api"), config.output_directory.to_s
    end
  end

  def test_loads_yaml_configuration
    Dir.mktmpdir do |directory|
      config = configuration_for(directory, <<~YAML)
        version: 1

        routes:
          prefix: /internal-api

        variables:
          base_url: https://example.test
      YAML

      assert_equal "/internal-api", config.route_prefix
      assert_equal "https://example.test", config.base_url
    end
  end

  def test_yaml_is_merged_into_defaults_without_dropping_them
    Dir.mktmpdir do |directory|
      config = configuration_for(directory, <<~YAML)
        sanitize:
          headers:
            X-Account-Id: "{{account_id}}"
      YAML

      assert_equal "{{account_id}}", config.sanitized_headers["X-Account-Id"]
      assert_equal "Bearer {{token}}", config.sanitized_headers["Authorization"]
      assert_equal "{{password}}", config.sanitized_body_keys["password"]
    end
  end

  def test_paths_are_an_alternative_to_a_command
    Dir.mktmpdir do |directory|
      config = configuration_for(directory, "test:\n  paths:\n    - test/integration\n    - test/api\n")

      assert_nil config.test_command
      assert_equal %w[test/integration test/api], config.test_paths
    end
  end

  def test_an_empty_command_counts_as_absent
    Dir.mktmpdir do |directory|
      assert_nil configuration_for(directory, "test:\n  command: \"\"\n").test_command
      assert_equal "bin/rails test test/api", configuration_for(directory, "test:\n  command: bin/rails test test/api\n").test_command
    end
  end

  def test_rejects_a_yaml_document_that_is_not_an_object
    Dir.mktmpdir do |directory|
      assert_raises(Reqcord::ConfigurationError) { configuration_for(directory, "- one\n- two\n") }
    end
  end

  def test_environment_overrides_the_file
    Dir.mktmpdir do |directory|
      ENV["REQCORD_BASE_URL"] = "https://staging.test"
      config = configuration_for(directory, "variables:\n  base_url: http://localhost:3000\n")

      assert_equal "https://staging.test", config.base_url
    ensure
      ENV.delete("REQCORD_BASE_URL")
    end
  end

  def test_knows_which_headers_are_transport_noise
    config = Reqcord::Configuration.load(root: Dir.pwd)

    assert config.noisy_header?("X-Request-Id")
    assert config.noisy_header?("Host")
    assert config.noisy_header?("User-Agent")
    refute config.noisy_header?("Content-Type")
    refute config.noisy_header?("Authorization")
  end
end

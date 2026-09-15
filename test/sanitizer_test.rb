# frozen_string_literal: true

require_relative "test_helper"

class SanitizerTest < Minitest::Test
  include Reqcord::TestHelpers

  def sanitize(raw, yaml = nil)
    Dir.mktmpdir do |directory|
      Reqcord::Sanitizers::Sanitizer.call(
        raw,
        configuration: configuration_for(directory, yaml)
      )
    end
  end

  def test_replaces_configured_authorization_header
    sanitized = sanitize(
      { "request" => { "headers" => { "Authorization" => "Bearer SECRET" } }, "response" => { "headers" => {} } },
      "sanitize:\n  headers:\n    Authorization: \"Bearer {{token}}\"\n"
    )

    assert_equal "Bearer {{token}}", sanitized.dig("request", "headers", "Authorization")
  end

  def test_keeps_the_scheme_for_unconfigured_secret_headers
    sanitized = sanitize(
      { "request" => { "headers" => { "X-Auth-Token" => "Token abc", "Cookie" => "session=1" } }, "response" => { "headers" => {} } }
    )

    assert_equal "Token {{x_auth_token}}", sanitized.dig("request", "headers", "X-Auth-Token")
    assert_equal "{{cookie}}", sanitized.dig("request", "headers", "Cookie")
  end

  def test_does_not_mutate_the_captured_exchange
    raw = { "request" => { "headers" => { "Authorization" => "Bearer SECRET" } }, "response" => { "headers" => {} } }
    sanitize(raw)

    assert_equal "Bearer SECRET", raw.dig("request", "headers", "Authorization")
  end

  def test_sanitizes_nested_body_keys
    sanitized = sanitize(
      {
        "request" => { "headers" => {}, "body" => { "user" => { "email" => "john@example.com", "password" => "hunter2" } } },
        "response" => { "headers" => {}, "body" => [{ "access_token" => "abc" }] }
      }
    )

    assert_equal "john@example.com", sanitized.dig("request", "body", "user", "email")
    assert_equal "{{password}}", sanitized.dig("request", "body", "user", "password")
    assert_equal "{{token}}", sanitized.dig("response", "body", 0, "access_token")
  end

  def test_drops_blank_and_noisy_headers
    sanitized = sanitize(
      {
        "request" => { "headers" => { "Cookie" => "", "X-Account-Id" => "42" } },
        "response" => { "headers" => { "X-Request-Id" => "abc", "Content-Type" => "application/json" } }
      }
    )

    refute sanitized.dig("request", "headers").key?("Cookie")
    assert_equal "42", sanitized.dig("request", "headers", "X-Account-Id")
    refute sanitized.dig("response", "headers").key?("X-Request-Id")
    assert_equal "application/json", sanitized.dig("response", "headers", "Content-Type")
  end
end

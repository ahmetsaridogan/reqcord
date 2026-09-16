# frozen_string_literal: true

module Reqcord
  class Configuration
    DEFAULTS = {
      "version" => 1,

      # No default command: with neither `command` nor `paths` the generator
      # falls back to `bin/rails test`, and `paths` alone must be able to win.
      "test" => {
        "framework" => "minitest",

        # A red suite still documents what its green tests captured; strict
        # runs abort instead, for CI that treats the docs as an artifact.
        "strict" => false
      },

      "routes" => {
        "prefix" => "/api"
      },

      "output" => {
        "directory" => "docs/api",

        # A route no test exercised is reported in the index; writing a page
        # with nothing on it only adds noise.
        "include_uncovered" => false
      },

      "exporters" => %w[curl markdown postman openapi],

      "variables" => {
        "base_url" => "http://localhost:3000"
      },

      "sanitize" => {
        "headers" => {
          "Authorization" => "Bearer {{token}}",
          "X-Api-Key" => "{{api_key}}"
        },

        "body" => {
          "password" => "{{password}}",
          "password_confirmation" => "{{password}}",
          "token" => "{{token}}",
          "access_token" => "{{token}}",
          "refresh_token" => "{{token}}",
          "api_key" => "{{api_key}}",
          "secret" => "{{secret}}",
          "client_secret" => "{{secret}}"
        }
      }
    }.freeze

    # Headers that describe the transport rather than the API. A documented
    # cURL that carries them is worse than one that does not: `Host` alone
    # would send the reader's request to the wrong virtual host.
    NOISY_HEADERS = %w[
      host
      user-agent
      connection
      version
      remote-addr
      accept-encoding
      cache-control
      content-length
      date
      etag
      server-timing
      transfer-encoding
      vary
      x-content-type-options
      x-download-options
      x-frame-options
      x-permitted-cross-domain-policies
      x-request-id
      x-runtime
      x-xss-protection
      referrer-policy
    ].freeze

    attr_reader :data, :root

    def self.load(root:)
      new(root: root).load
    end

    def initialize(root:)
      @root = Pathname(root)
      @data = deep_dup(DEFAULTS)
    end

    def load
      path = root.join("reqcord.yml")

      return self unless path.exist?

      raw = YAML.safe_load_file(
        path,
        aliases: false
      ) || {}

      unless raw.is_a?(Hash)
        raise ConfigurationError,
              "reqcord.yml must contain a YAML object"
      end

      @data = deep_merge(@data, stringify_keys(raw))

      self
    end

    def test_framework
      ENV["REQCORD_TEST_FRAMEWORK"] ||
        data.dig("test", "framework")
    end

    # An explicit command wins; nil means "build one from test.paths".
    def test_command
      value = ENV["REQCORD_TEST_COMMAND"] || data.dig("test", "command")

      value.to_s.empty? ? nil : value.to_s
    end

    # Directories, files or globs the suite lives in; Reqcord picks the runner.
    def test_paths
      Array(data.dig("test", "paths")).map(&:to_s)
    end

    # Abort on a failing suite instead of documenting what was captured.
    def strict_tests?
      value = ENV.fetch("REQCORD_STRICT") { data.dig("test", "strict") }

      [true, "true", "1"].include?(value)
    end

    # `prefix: /api` or `prefix: [/v1, /v2]`; a route under any of them is
    # documented. Empty means every route.
    def route_prefixes
      Array(data.dig("routes", "prefix")).map(&:to_s).reject(&:empty?)
    end

    def route_prefix
      route_prefixes.first
    end

    def output_directory
      return Pathname(@output_override) if @output_override

      value =
        ENV["REQCORD_OUTPUT"] ||
        data.dig("output", "directory") ||
        "docs/api"

      root.join(value)
    end

    # The same configuration writing somewhere else — how `reqcord:check`
    # generates into a scratch directory while the configured one stays the
    # thing to compare against.
    def with_output_directory(path)
      dup.tap { |copy| copy.instance_variable_set(:@output_override, path.to_s) }
    end

    def include_uncovered?
      data.dig("output", "include_uncovered") == true
    end

    def exporters
      Array(data["exporters"]).map(&:to_s)
    end

    def variables
      (data["variables"] || {}).merge(
        "base_url" => base_url
      )
    end

    def base_url
      ENV["REQCORD_BASE_URL"] ||
        data.dig("variables", "base_url") ||
        "http://localhost:3000"
    end

    def sanitized_headers
      data.dig("sanitize", "headers") || {}
    end

    def sanitized_body_keys
      data.dig("sanitize", "body") || {}
    end

    def noisy_header?(key)
      NOISY_HEADERS.include?(key.to_s.downcase)
    end

    private

    def deep_merge(left, right)
      left.merge(right) do |_key, old_value, new_value|
        if old_value.is_a?(Hash) && new_value.is_a?(Hash)
          deep_merge(old_value, new_value)
        else
          new_value
        end
      end
    end

    def deep_dup(value)
      Marshal.load(Marshal.dump(value))
    end

    def stringify_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        result[key.to_s] =
          if value.is_a?(Hash)
            stringify_keys(value)
          else
            value
          end
      end
    end
  end
end

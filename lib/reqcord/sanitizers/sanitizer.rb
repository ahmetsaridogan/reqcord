# frozen_string_literal: true

module Reqcord
  module Sanitizers
    # Works on a raw captured exchange, before anything reaches the dataset:
    # credentials must never be written to a generated file.
    class Sanitizer
      DEFAULT_SECRET_HEADERS = %w[
        Authorization
        Proxy-Authorization
        Cookie
        Set-Cookie
        X-Api-Key
        X-Auth-Token
        X-Csrf-Token
      ].freeze

      SCHEME_PATTERN = /\A(Bearer|Token|Basic)\s+/i

      def self.call(exchange, configuration:)
        new(
          exchange,
          configuration: configuration
        ).call
      end

      def initialize(exchange, configuration:)
        @exchange = deep_dup(exchange)
        @configuration = configuration
      end

      def call
        sanitize_headers!(
          exchange.dig("request", "headers")
        )

        sanitize_headers!(
          exchange.dig("response", "headers"),
          response: true
        )

        sanitize_body!("request")
        sanitize_body!("response")

        exchange
      end

      private

      attr_reader :exchange, :configuration

      def sanitize_headers!(headers, response: false)
        return unless headers.is_a?(Hash)

        replacements = configuration.sanitized_headers

        headers.keys.each do |key|
          if configuration.noisy_header?(key)
            headers.delete(key)
            next
          end

          if blank?(headers[key])
            headers.delete(key)
            next
          end

          replacement = find_replacement(replacements, key)

          if replacement
            headers[key] = replacement
            next
          end

          headers[key] = redact(key, headers[key]) if secret_header?(key)
        end
      end

      def sanitize_body!(side)
        body = exchange.dig(side, "body")

        return unless body.is_a?(Hash) || body.is_a?(Array)

        exchange[side]["body"] = sanitize_value(body)
      end

      def sanitize_value(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), result|
            replacement = body_replacement(key)

            result[key] = replacement || sanitize_value(nested)
          end
        when Array
          value.map { |item| sanitize_value(item) }
        else
          value
        end
      end

      def body_replacement(key)
        configuration.sanitized_body_keys.find do |name, _value|
          name.to_s.casecmp?(key.to_s)
        end&.last
      end

      def find_replacement(replacements, key)
        pair = replacements.find do |header, _value|
          header.to_s.casecmp?(key.to_s)
        end

        pair&.last
      end

      # The scheme is kept so the generated cURL stays copy-pasteable.
      def redact(key, value)
        placeholder = "{{#{key.to_s.tr('-', '_').downcase}}}"

        match = value.to_s.match(SCHEME_PATTERN)

        match ? "#{match[1]} #{placeholder}" : placeholder
      end

      def secret_header?(key)
        DEFAULT_SECRET_HEADERS.any? do |header|
          header.casecmp?(key.to_s)
        end
      end

      def blank?(value)
        value.nil? || value.to_s.empty?
      end

      def deep_dup(value)
        Marshal.load(Marshal.dump(value))
      end
    end
  end
end

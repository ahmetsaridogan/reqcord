# frozen_string_literal: true

module Reqcord
  module Renderers
    class Curl
      def self.call(request, base_url:)
        new(
          request,
          base_url: base_url
        ).call
      end

      def initialize(request, base_url:)
        @request = request
        @base_url = base_url.to_s.sub(%r{/$}, "")
      end

      def call
        parts = [
          "curl --request #{request.method}",
          %(--url "#{url}")
        ]

        request.headers.each do |key, value|
          parts << %(--header "#{key}: #{escape_header(value)}")
        end

        parts << data_argument if request.body?

        parts.join(" \\\n  ")
      end

      private

      attr_reader :request, :base_url

      def url
        "#{base_url}#{Payload.path_with_query(request)}"
      end

      def data_argument
        "--data '#{shell_single_quote(Payload.raw_body(request))}'"
      end

      def shell_single_quote(value)
        value.to_s.gsub("'", %q('"'"'))
      end

      def escape_header(value)
        value.to_s
             .gsub("\\") { "\\\\" }
             .gsub('"') { '\\"' }
      end
    end
  end
end

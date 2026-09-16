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
          next if key.to_s.casecmp?("Content-Type") && Payload.multipart?(request)

          parts << %(--header "#{key}: #{escape_header(value)}")
        end

        if request.body?
          parts.concat(Payload.multipart?(request) ? form_arguments : [data_argument])
        end

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

      # One --form per part; a file is `@name`, relative to where the reader
      # runs the command. curl sets the multipart Content-Type itself, so a
      # captured one would only get in the way.
      def form_arguments
        Payload.form_pairs(request).map do |key, value|
          part =
            if FileValue.file?(value)
              type = FileValue.content_type(value)
              "#{key}=@#{FileValue.filename(value)}#{type ? ";type=#{type}" : ''}"
            else
              "#{key}=#{value}"
            end

          "--form '#{shell_single_quote(part)}'"
        end
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

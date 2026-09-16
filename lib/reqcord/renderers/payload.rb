# frozen_string_literal: true

module Reqcord
  module Renderers
    # The wire-level decisions every output format has to agree on: whether a
    # request is JSON, a form or a multipart upload, how a nested query
    # flattens, what the body looks like as text. cURL, Postman and any later
    # exporter read these, never their own copy.
    module Payload
      module_function

      def json?(request)
        request.content_type.to_s.include?("json") ||
          request.headers.any? do |key, value|
            key.to_s.casecmp?("Content-Type") && value.to_s.include?("json")
          end
      end

      # A body with a file in it can only travel as multipart/form-data,
      # whatever the captured content type says.
      def multipart?(request)
        request.content_type.to_s.include?("multipart/form-data") ||
          FileValue.any?(request.body)
      end

      # Rails bracket notation: { filter: { status: "a" }, ids: [1, 2] } becomes
      # [["filter[status]", "a"], ["ids[]", 1], ["ids[]", 2]]. A file marker is
      # a leaf: the pair's value is the marker itself.
      def flatten_query(hash, prefix = nil)
        hash.flat_map do |key, value|
          current = prefix ? "#{prefix}[#{key}]" : key.to_s

          case value
          when Hash
            FileValue.file?(value) ? [[current, value]] : flatten_query(value, current)
          when Array
            value.flat_map do |item|
              if item.is_a?(Hash) && !FileValue.file?(item)
                flatten_query(item, "#{current}[]")
              else
                [["#{current}[]", item]]
              end
            end
          else
            [[current, value]]
          end
        end
      end

      def query_pairs(request)
        flatten_query(request.query_params)
      end

      def form_pairs(request)
        request.body.is_a?(Hash) ? flatten_query(request.body) : []
      end

      def path_with_query(request)
        return request.path if request.query_params.empty?

        "#{request.path}?#{URI.encode_www_form(query_pairs(request))}"
      end

      # The body as it goes on the wire: pretty JSON, a form string, or the
      # raw text the test sent. Multipart has no single string; callers use
      # form_pairs and render each part.
      def raw_body(request)
        if json?(request)
          JSON.pretty_generate(request.body)
        elsif request.body.is_a?(Hash)
          URI.encode_www_form(form_pairs(request))
        else
          request.body.to_s
        end
      end

      # The body as a reader should see it: file markers replaced by their
      # description ("avatar.png (image/png)"), or by whatever the block
      # returns.
      def display_body(request, &block)
        block ||= FileValue.method(:describe)

        FileValue.map(request.body, &block)
      end
    end
  end
end

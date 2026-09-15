# frozen_string_literal: true

module Reqcord
  module Capture
    # Captures exactly what the integration test passed to Rails. Reqcord does
    # not reconstruct the payload from controller params: the test call is the
    # source of truth for generated cURL examples.
    module IntegrationPatch
      RAILS_DEFAULT_ACCEPT =
        "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"

      def process(method, path, **kwargs)
        raw_params = kwargs[:params]
        raw_headers = kwargs[:headers]
        request_format = kwargs[:as]

        result = super

        if Reqcord::Capture.enabled?
          Reqcord::Capture::Collector.write(
            reqcord_exchange(
              method: method,
              path: path,
              params: raw_params,
              input_headers: raw_headers,
              request_format: request_format
            )
          )
        end

        result
      end

      private

      def reqcord_exchange(method:, path:, params:, input_headers:, request_format:)
        verb = method.to_s.upcase
        query_params, body = reqcord_split_params(verb, path, params)

        {
          request: {
            method: verb,
            path: reqcord_request_path(path),
            path_params: reqcord_path_parameters,
            query_params: query_params,
            headers: reqcord_request_headers(input_headers, body, request_format),
            body: body,
            content_type: reqcord_content_type(body, request_format)
          },
          response: {
            status: response&.status,
            headers: reqcord_response_headers,
            body: reqcord_response_body,
            content_type: response&.media_type
          },
          source: TestContext.current
        }
      end

      # Keep the concrete test URL (/customers/42), not the route pattern
      # (/customers/:id). A generated cURL command must be runnable as-is.
      def reqcord_request_path(path)
        URI.parse(path.to_s).path
      rescue URI::InvalidURIError
        path.to_s.split("?").first
      end

      def reqcord_path_parameters
        return {} unless request

        request.path_parameters
               .except(:controller, :action, :format)
               .transform_keys(&:to_s)
      end

      # Rails integration tests use params as query parameters for GET/HEAD and
      # as the request payload for mutating verbs. Read the original test input
      # instead of trying to reverse-engineer it from ActionDispatch afterwards.
      def reqcord_split_params(verb, path, params)
        explicit_query = reqcord_query_from_path(path)
        normalized = reqcord_normalize_value(params)

        if %w[GET HEAD].include?(verb)
          query = explicit_query
          query = reqcord_deep_merge(query, normalized) if normalized.is_a?(Hash)
          [query, nil]
        else
          [explicit_query, reqcord_meaningful?(normalized) ? normalized : nil]
        end
      end

      def reqcord_query_from_path(path)
        uri = URI.parse(path.to_s)
        return {} if uri.query.nil? || uri.query.empty?

        Rack::Utils.parse_nested_query(uri.query)
      rescue URI::InvalidURIError
        {}
      end

      def reqcord_request_headers(input_headers, body, request_format)
        result = {}

        (input_headers || {}).each do |key, value|
          result[reqcord_header_name(key)] = reqcord_normalize_value(value)
        end

        result.delete("X-Http-Method-Override")

        if body
          content_type = reqcord_content_type(body, request_format)
          result["Content-Type"] ||= content_type if content_type
        end

        if request
          accept = request.headers["Accept"]
          result["Accept"] ||= accept if accept.present? && accept != RAILS_DEFAULT_ACCEPT
        end

        result
      end

      def reqcord_content_type(body, request_format)
        return nil unless body

        return "application/json" if request_format.to_s == "json"

        request&.content_type
      end

      def reqcord_header_name(key)
        name = key.to_s

        return name if name.include?("-")

        name.delete_prefix("HTTP_")
            .split("_")
            .map { |part| part.empty? ? part : part.capitalize }
            .join("-")
      end

      def reqcord_response_headers
        return {} unless response

        response.headers.to_h
      end

      def reqcord_response_body
        return nil unless response

        body = response.body
        return nil if body.nil? || body.empty?

        if response.media_type == "application/json"
          JSON.parse(body)
        else
          body
        end
      rescue JSON::ParserError
        body
      end

      def reqcord_normalize_value(value)
        case value
        when nil, true, false, Numeric, String
          value
        when Symbol
          value.to_s
        when Hash
          value.each_with_object({}) do |(key, nested), result|
            result[key.to_s] = reqcord_normalize_value(nested)
          end
        when Array
          value.map { |item| reqcord_normalize_value(item) }
        else
          if value.respond_to?(:to_unsafe_h)
            reqcord_normalize_value(value.to_unsafe_h)
          elsif value.respond_to?(:to_h)
            reqcord_normalize_value(value.to_h)
          elsif value.respond_to?(:as_json)
            reqcord_normalize_value(value.as_json)
          else
            value.to_s
          end
        end
      end

      def reqcord_deep_merge(left, right)
        left.merge(right) do |_key, old_value, new_value|
          if old_value.is_a?(Hash) && new_value.is_a?(Hash)
            reqcord_deep_merge(old_value, new_value)
          else
            new_value
          end
        end
      end

      def reqcord_meaningful?(value)
        case value
        when nil then false
        when Hash then value.any? { |_key, nested| reqcord_meaningful?(nested) }
        when Array then value.any? { |item| reqcord_meaningful?(item) }
        when String then !value.empty?
        else true
        end
      end
    end
  end
end

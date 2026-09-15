# frozen_string_literal: true

module Reqcord
  class RequestExample
    ATTRIBUTES = %i[
      name
      method
      path
      path_params
      query_params
      headers
      body
      content_type
      response_status
      source
    ].freeze

    attr_accessor(*ATTRIBUTES)

    def initialize(
      method:,
      path:,
      name: nil,
      path_params: {},
      query_params: {},
      headers: {},
      body: nil,
      content_type: nil,
      response_status: nil,
      source: {}
    )
      @name = name
      @method = method.to_s.upcase
      @path = path
      @path_params = path_params || {}
      @query_params = query_params || {}
      @headers = headers || {}
      @body = body
      @content_type = content_type
      @response_status = response_status&.to_i
      @source = source || {}
    end

    # `method` is the HTTP verb here; this alias keeps call sites that mean the
    # verb from reading like reflection.
    def http_method
      method
    end

    # A payload of empty containers ({"experience" => {}}) carries nothing to
    # document, and sending it as --data would only mislead.
    def body?
      meaningful?(body)
    end

    # The request the endpoint page leads with should be one that worked.
    def successful?
      response_status.nil? ? false : (200..299).cover?(response_status)
    end

    # Identical requests captured by several tests are stored once — but the
    # same request that produced a different status is a different example.
    # Sanitization can make a right and a wrong password look identical; the
    # 200 must not be dropped because the 401 was captured first.
    def signature
      JSON.generate([method, path, headers, query_params, body, response_status])
    end

    def to_h
      {
        name: name,
        method: method,
        path: path,
        path_params: path_params,
        query_params: query_params,
        headers: headers,
        body: body,
        content_type: content_type,
        response_status: response_status,
        source: source
      }
    end

    # Tolerates keys this version does not know, so a dataset written by a
    # newer Reqcord still loads.
    def self.from_h(hash)
      hash = hash.transform_keys(&:to_sym).slice(*ATTRIBUTES)

      new(**hash)
    end

    private

    def meaningful?(value)
      case value
      when nil then false
      when Hash then value.any? { |_key, nested| meaningful?(nested) }
      when Array then value.any? { |item| meaningful?(item) }
      when String then !value.empty?
      else true
      end
    end
  end
end

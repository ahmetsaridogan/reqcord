# frozen_string_literal: true

module Reqcord
  class ResponseExample
    ATTRIBUTES = %i[
      name
      status
      headers
      body
      content_type
      source
    ].freeze

    attr_accessor(*ATTRIBUTES)

    def initialize(
      status:,
      name: nil,
      headers: {},
      body: nil,
      content_type: nil,
      source: {}
    )
      @name = name
      @status = status.to_i
      @headers = headers || {}
      @body = body
      @content_type = content_type
      @source = source || {}
    end

    # "201 Created"
    def status_text
      Rack::Utils::HTTP_STATUS_CODES[status] || "Unknown"
    end

    def title
      "#{status} #{status_text}"
    end

    def body?
      !(body.nil? || (body.respond_to?(:empty?) && body.empty?))
    end

    def empty_body?
      !body?
    end

    def signature
      JSON.generate([status, body])
    end

    def to_h
      {
        name: name,
        status: status,
        headers: headers,
        body: body,
        content_type: content_type,
        source: source
      }
    end

    # Tolerates keys this version does not know, so a dataset written by a
    # newer Reqcord still loads.
    def self.from_h(hash)
      hash = hash.transform_keys(&:to_sym).slice(*ATTRIBUTES)

      new(**hash)
    end
  end
end

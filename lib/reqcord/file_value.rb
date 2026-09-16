# frozen_string_literal: true

module Reqcord
  # How an uploaded file travels through the dataset. The capture cannot keep
  # the bytes (and the documentation must not), so a file becomes a small
  # marker hash — `{"$file" => "avatar.png", "content_type" => "image/png"}` —
  # that every renderer recognizes: `--form avatar=@avatar.png` in cURL, a
  # `file` entry in Postman, `format: binary` in OpenAPI, type `file` in the
  # parameter tables.
  module FileValue
    KEY = "$file"

    module_function

    def marker(filename, content_type = nil)
      { KEY => filename.to_s, "content_type" => content_type.to_s.empty? ? nil : content_type.to_s }.compact
    end

    def file?(value)
      value.is_a?(Hash) && value.key?(KEY)
    end

    def filename(value)
      value[KEY].to_s
    end

    def content_type(value)
      value["content_type"]
    end

    # "avatar.png (image/png)" — how a page shows the upload.
    def describe(value)
      type = content_type(value)

      type ? "#{filename(value)} (#{type})" : filename(value)
    end

    # True when any value, at any depth, is a file marker.
    def any?(value)
      case value
      when Hash then file?(value) || value.values.any? { |nested| any?(nested) }
      when Array then value.any? { |item| any?(item) }
      else false
      end
    end

    # Returns a copy of `value` with every marker replaced by the block's
    # result; used to render the body for a reader.
    def map(value, &block)
      case value
      when Hash
        return yield(value) if file?(value)

        value.transform_values { |nested| map(nested, &block) }
      when Array
        value.map { |item| map(item, &block) }
      else
        value
      end
    end
  end
end

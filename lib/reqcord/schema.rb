# frozen_string_literal: true

module Reqcord
  # Describes what an endpoint accepts, inferred from the requests that
  # actually worked. One test sends status "active", another "passive", a third
  # sends "inactive" and gets a 422: the documentation should say the field
  # takes "active" | "passive", not list three requests.
  class Schema
    # Beyond this many distinct values a field is an open set, not a choice.
    ENUM_LIMIT = 6

    Field = Struct.new(:path, :types, :values, :present_count, :total_count, :repetition, keyword_init: true) do
      def type
        types.to_a.sort.join(" | ")
      end

      # A field missing from a working request cannot be required.
      def required?
        present_count == total_count
      end

      # Telling a closed set from free text: either a value came back in more
      # than one request, or every value reads like a token ("active"), not
      # like content ("Ada Lovelace", "ada@example.com").
      def enum?
        return false unless values.size.between?(2, ENUM_LIMIT)
        return false unless values.all? { |value| scalar?(value) }
        return false if identifier?

        # Repetition only counts among the requests that carried the field:
        # two requests, two different values, is not a set.
        return true if repetition && values.size < present_count

        values.all? { |value| token?(value) }
      end

      def example
        values.first
      end

      # Test order is not stable, so a listed set must be ordered by something
      # that is.
      def listed_values
        values.sort_by { |value| [value.to_s, value.class.name] }
      end

      def to_h
        {
          path: path,
          type: type,
          required: required?,
          values: listed_values
        }
      end

      private

      def scalar?(value)
        value.is_a?(String) || value.is_a?(Numeric) || value == true || value == false
      end

      # Every record has a different one, so listing the ones a test happened
      # to use would read as if those were the only allowed values.
      def identifier?
        path.to_s.split(/[.\[\]]/).last.to_s.match?(/\A(id|uuid|.*_id|.*_uuid|.*_key|token|slug)\z/i)
      end

      # A word, not content: "active", "pending_review", "USD". Digits and
      # dashes usually mean a generated value ("e-00056197", "safari-859f04").
      def token?(value)
        case value
        when true, false then true
        when String then value.match?(/\A[a-z][a-z_]*\z/) || value.match?(/\A[A-Z_]{2,}\z/)
        else false
        end
      end
    end

    # `payloads` are request bodies, query hashes or path parameter hashes from
    # successful captures. With `repetition: true` a value seen in more than
    # one payload marks a closed set — right for what tests *send*, wrong for
    # what an application *returns*, where fixtures repeat by nature; response
    # bodies are inferred with `repetition: false`, so only token-like values
    # ("open", "done") are listed as a set.
    def self.infer(payloads, repetition: true)
      new(payloads, repetition: repetition).call
    end

    # Empty payloads are kept: a request that was accepted without any
    # parameters is the proof that every parameter is optional.
    def initialize(payloads, repetition: true)
      @payloads = Array(payloads)
      @repetition = repetition
    end

    def call
      return self.class.empty if @payloads.empty?

      fields = {}

      @payloads.each do |payload|
        flatten(payload).each do |path, value|
          field = fields[path] ||= Field.new(
            path: path,
            types: [],
            values: [],
            present_count: 0,
            total_count: @payloads.size,
            repetition: @repetition
          )

          field.types |= [type_of(value)]
          field.values |= [value] unless value.nil? || value.is_a?(Hash) || value.is_a?(Array)
          field.present_count += 1
        end
      end

      Result.new(fields.values)
    end

    def self.empty
      Result.new([])
    end

    # The inferred description of one payload shape.
    class Result
      include Enumerable

      attr_reader :fields

      def initialize(fields)
        @fields = fields
      end

      def each(&block)
        fields.each(&block)
      end

      def empty?
        fields.empty?
      end

      def size
        fields.size
      end

      def [](path)
        fields.find { |field| field.path == path }
      end

      def to_a
        fields.map(&:to_h)
      end
    end

    private

    # { "customer" => { "tags" => ["a"] } } -> { "customer.tags[]" => "a" }
    def flatten(value, prefix = nil, result = {})
      case value
      when Hash
        value.each { |key, nested| flatten(nested, prefix ? "#{prefix}.#{key}" : key.to_s, result) }
      when Array
        # An empty array still tells the reader the field is a list.
        result[prefix] = [] if value.empty? && prefix
        value.each { |item| flatten(item, "#{prefix}[]", result) }
      else
        result[prefix] = value if prefix
      end

      result
    end

    def type_of(value)
      case value
      when String then "string"
      when Integer then "integer"
      when Float then "number"
      when true, false then "boolean"
      when nil then "null"
      when Array then "array"
      when Hash then "object"
      else value.class.name.downcase
      end
    end
  end
end

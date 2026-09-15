# frozen_string_literal: true

module Reqcord
  # Minimal inflection helpers. ActiveSupport is used when it is available so
  # that generated titles match the host application's inflections.
  module Support
    module_function

    def underscore(value)
      string = value.to_s.dup
      return ActiveSupport::Inflector.underscore(string) if defined?(ActiveSupport::Inflector)

      string.gsub("::", "/")
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr("-", "_")
            .downcase
    end

    def humanize(value)
      underscore(value).tr("_", " ").strip
    end

    def titleize(value)
      humanize(value).split(/\s+/).map { |word| word.empty? ? word : word[0].upcase + word[1..] }.join(" ")
    end

    def singularize(value)
      string = value.to_s
      return ActiveSupport::Inflector.singularize(string) if defined?(ActiveSupport::Inflector)

      case string
      when /ies\z/i then string.sub(/ies\z/i, "y")
      when /(ss|sh|ch|x|z)es\z/i then string.sub(/es\z/i, "")
      when /ss\z/i then string
      when /s\z/i then string.sub(/s\z/i, "")
      else string
      end
    end

    def pluralize(value)
      string = value.to_s
      return ActiveSupport::Inflector.pluralize(string) if defined?(ActiveSupport::Inflector)

      case string
      when /(ss|sh|ch|x|z)\z/i then "#{string}es"
      when /[^aeiou]y\z/i then string.sub(/y\z/i, "ies")
      # Already plural, as resource names usually are.
      when /s\z/i then string
      else "#{string}s"
      end
    end

    def parameterize(value)
      underscore(value).gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    end
  end
end

# frozen_string_literal: true

module Reqcord
  # Exporters register themselves here, so adding one means adding a file
  # rather than editing the pipeline.
  module Exporters
    class << self
      def register(name, exporter)
        registry[name.to_s] = exporter
      end

      def fetch(name)
        registry.fetch(name.to_s) do
          raise ConfigurationError,
                "unknown exporter #{name.inspect}, expected one of #{names.join(', ')}"
        end
      end

      def registered?(name)
        registry.key?(name.to_s)
      end

      def names
        registry.keys.sort
      end

      def registry
        @registry ||= {}
      end
    end
  end
end

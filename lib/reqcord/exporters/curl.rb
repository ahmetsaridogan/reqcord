# frozen_string_literal: true

module Reqcord
  module Exporters
    # Writes one runnable .sh file per covered endpoint. The command is always
    # rendered from the endpoint's successful captured request when available.
    class Curl
      def self.call(dataset:, output_dir:, configuration:)
        new(
          dataset: dataset,
          output_dir: output_dir,
          configuration: configuration
        ).call
      end

      def initialize(dataset:, output_dir:, configuration:)
        @dataset = dataset
        @output_dir = Pathname(output_dir).join("curl")
        @configuration = configuration
      end

      def call
        FileUtils.mkdir_p(output_dir)

        dataset.resources.flat_map do |resource|
          basenames = resource.file_basenames

          resource.endpoints.filter_map do |endpoint|
            next unless endpoint.curl_ready?

            example = endpoint.primary_request_example

            directory = output_dir.join(resource.slug)
            FileUtils.mkdir_p(directory)

            path = directory.join("#{basenames.fetch(endpoint)}.sh")
            File.write(path, script(endpoint, example))
            File.chmod(0o755, path)

            path.to_s
          end
        end
      end

      private

      attr_reader :dataset, :output_dir, :configuration

      def script(endpoint, example)
        command = Renderers::Curl.call(
          example,
          base_url: configuration.base_url
        )

        <<~SH
          #!/usr/bin/env bash
          set -euo pipefail

          # #{endpoint.name}
          # #{endpoint.method} #{endpoint.path}
          #{command}
        SH
      end
    end

    register("curl", Curl)
  end
end

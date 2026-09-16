# frozen_string_literal: true

require "tmpdir"

module Reqcord
  # `reqcord:check`: generates the documentation into a scratch directory and
  # compares it with the committed one, file by file. The output is a
  # function of the routes and the tests, so any difference means the docs
  # in the repository are behind the code — the CI signal a "living
  # documentation" promise needs.
  class Check
    Result = Struct.new(:added, :removed, :changed, keyword_init: true) do
      def clean?
        added.empty? && removed.empty? && changed.empty?
      end

      # git-status style, one line per file.
      def lines
        added.map { |path| "A #{path}" } +
          removed.map { |path| "D #{path}" } +
          changed.map { |path| "M #{path}" }
      end
    end

    def self.call(resources: [], version: nil, configuration: Reqcord.configuration)
      new(resources: resources, version: version, configuration: configuration).call
    end

    # `expected` is what the repository holds, `actual` what the code produces.
    def self.compare(expected:, actual:)
      expected_files = files_under(expected)
      actual_files = files_under(actual)

      Result.new(
        added: (actual_files - expected_files).sort,
        removed: (expected_files - actual_files).sort,
        changed: (expected_files & actual_files).sort.reject do |path|
          FileUtils.identical?(File.join(expected, path), File.join(actual, path))
        end
      )
    end

    def self.files_under(directory)
      return [] unless File.directory?(directory)

      Dir.glob("**/*", File::FNM_DOTMATCH, base: directory).select do |path|
        File.file?(File.join(directory, path))
      end
    end

    def initialize(resources:, version:, configuration:)
      @resources = resources
      @version = version
      @configuration = configuration
    end

    def call
      Dir.mktmpdir("reqcord-check") do |scratch|
        Generator.call(
          resources: resources,
          version: version,
          configuration: configuration.with_output_directory(scratch)
        )

        self.class.compare(expected: configuration.output_directory.to_s, actual: scratch)
      end
    end

    private

    attr_reader :resources, :version, :configuration
  end
end

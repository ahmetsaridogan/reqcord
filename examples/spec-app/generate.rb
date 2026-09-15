# frozen_string_literal: true

# Stands in for `bin/rails reqcord:generate`, which this single file example
# has no `bin/rails` to run.
require_relative "app"

dataset = Reqcord::Generator.call(
  resources: ENV.fetch("RESOURCE", "").split(",").map(&:strip).reject(&:empty?),
  version: ENV["VERSION"]
)

puts
puts "Endpoints: #{dataset.endpoints.size} (#{dataset.documented_endpoints.size} covered by tests)"
puts "Output: #{Reqcord.configuration.output_directory}"

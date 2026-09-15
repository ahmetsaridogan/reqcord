# frozen_string_literal: true

# Entry point for the pipeline test: boots the dummy application and runs the
# generator exactly as `bin/rails reqcord:generate` would.
require_relative "app_boot"

resources = ENV.fetch("RESOURCE", "").split(",").map(&:strip).reject(&:empty?)
version = ENV["VERSION"]

dataset = Reqcord::Generator.call(resources: resources, version: version)

puts "endpoints=#{dataset.endpoints.size} documented=#{dataset.documented_endpoints.size}"

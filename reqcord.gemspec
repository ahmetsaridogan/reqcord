# frozen_string_literal: true

require_relative "lib/reqcord/version"

Gem::Specification.new do |spec|
  spec.name = "reqcord"
  spec.version = Reqcord::VERSION

  spec.authors = ["Ahmet Saridogan"]

  spec.summary = "Generate living API documentation from Rails integration tests"
  spec.description = <<~DESC
    Reqcord captures HTTP requests and responses from Rails integration tests
    and generates static API documentation with executable cURL examples.
  DESC

  spec.homepage = "https://github.com/ahmetsaridogan/reqcord"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |file|
      file.start_with?(
        "test/",
        "spec/",
        "features/",
        ".git/",
        ".github/"
      ) || file.end_with?(".gem")
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 8.0", "< 9.0"
  spec.add_dependency "actionpack", ">= 8.0", "< 9.0"

  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
end

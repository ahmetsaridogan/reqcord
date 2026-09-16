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
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/tree/master/docs"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  # What ships: lib/, the rake task, the docs and the annotated config. Tests,
  # CI files and the example apps (with their generated output) stay on
  # GitHub — `git ls-files` runs against the checkout, so `gem build` must be
  # run from the repository root.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |file|
      file.start_with?(
        "test/",
        "spec/",
        "features/",
        "examples/",
        ".git",
        ".github/"
      ) || file.end_with?(".gem")
    end + ["examples/reqcord.yml"]
  end

  spec.require_paths = ["lib"]

  # Rails 7.1 through 8.x; every version is exercised in CI (see gemfiles/).
  spec.add_dependency "railties", ">= 7.1", "< 9.0"
  spec.add_dependency "actionpack", ">= 7.1", "< 9.0"

  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"

  # The test suite serves the dummy app over HTTP to replay the generated
  # cURL and Postman collection, validates the collection against the
  # Postman schema, and runs the RSpec example apps.
  spec.add_development_dependency "puma"
  spec.add_development_dependency "json-schema"
  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "rspec-expectations"
end

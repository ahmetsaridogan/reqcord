# frozen_string_literal: true

namespace :reqcord do
  desc "Create reqcord.yml"
  task init: :environment do
    path = Rails.root.join("reqcord.yml")

    if path.exist?
      puts "reqcord.yml already exists."
      next
    end

    content = <<~YAML
      version: 1

      test:
        framework: minitest
        command: bin/rails test

      routes:
        prefix: /api

      output:
        directory: docs/api
        include_uncovered: false

      exporters:
        - curl
        - markdown
        - postman

      variables:
        base_url: http://localhost:3000

      sanitize:
        headers:
          Authorization: "Bearer {{token}}"
          X-Api-Key: "{{api_key}}"
    YAML

    File.write(path, content)

    FileUtils.mkdir_p(
      Rails.root.join("docs", "api")
    )

    puts "Created reqcord.yml"
    puts "Created docs/api/"
  end

  desc "Generate API documentation from Rails integration tests"
  task generate: :environment do
    resources =
      ENV.fetch("RESOURCE", "")
         .split(",")
         .map(&:strip)
         .reject(&:empty?)

    version = ENV["VERSION"]&.strip

    version = nil if version&.empty?

    Reqcord.reload_configuration!

    dataset =
      Reqcord::Generator.call(
        resources: resources,
        version: version
      )

    documented = dataset.curl_ready_endpoints.size

    puts
    puts "Reqcord generated API documentation."
    puts "Endpoints: #{dataset.endpoints.size} (#{documented} with successful 2xx request)"
    puts "Output: #{Reqcord.configuration.output_directory}"
  end

  desc "List the routes Reqcord would document"
  task routes: :environment do
    routes =
      Reqcord::RouteCollector.call(
        resources: ENV.fetch("RESOURCE", "").split(",").map(&:strip).reject(&:empty?),
        version: ENV["VERSION"],
        prefix: Reqcord.configuration.route_prefix
      )

    if routes.empty?
      puts "No routes matched the configured prefix."
      next
    end

    width = routes.map { |route| route.method.length }.max

    routes.each do |route|
      puts format("%-#{width}s %s  (%s#%s)", route.method, route.path, route.controller, route.action)
    end
  end
end

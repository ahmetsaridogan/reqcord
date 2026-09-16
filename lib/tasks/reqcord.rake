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
      # Reqcord configuration. Every key is documented in the gem's
      # docs/configuration.md. Precedence: environment > this file > defaults.
      version: 1

      test:
        # minitest or rspec
        framework: minitest

        # The tests that exercise your API. Reqcord runs `bin/rails test <paths>`
        # (or `rspec <paths>`) with capture enabled; a directory is enough.
        paths:
          - test/integration

        # Or spell the command out yourself; it wins over `paths`.
        # command: bin/rails test test/integration test/api

        # A failing suite still documents what it captured. Set true to abort
        # instead (or run with REQCORD_STRICT=1).
        # strict: false

      routes:
        # Only routes under this prefix are documented; a list works too
        # (`prefix: [/v1, /v2]`). Filter a single run with
        # RESOURCE=customers,cart or VERSION=v2.
        prefix: /api

      output:
        directory: docs/api

        # Routes no test reached with a 2xx are listed in the index either
        # way; `true` also writes a page for each of them.
        include_uncovered: false

      # markdown: pages under docs/api, curl: one runnable .sh per endpoint,
      # postman: postman/collection.json (import into Postman or Hoppscotch),
      # openapi: openapi/openapi.json (rendered with Scalar by Reqcord::Web).
      exporters:
        - curl
        - markdown
        - postman
        - openapi

      variables:
        # Host of every generated cURL and the Postman `base_url` variable.
        base_url: http://localhost:3000

      sanitize:
        # Header values are replaced verbatim. Authorization, Cookie and
        # X-Api-Key are always redacted, configured here or not.
        headers:
          Authorization: "Bearer {{token}}"
          X-Api-Key: "{{api_key}}"

        # Body keys, matched at any depth in requests and responses. password,
        # token, access_token, api_key, secret are always redacted; add the
        # fields your API exposes (a signed payment link, for example).
        body:
          password: "{{password}}"
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
        prefix: Reqcord.configuration.route_prefixes
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

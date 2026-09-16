# frozen_string_literal: true

require "rack/mime"

module Reqcord
  # Serves the generated documentation from inside the application, the way
  # Sidekiq::Web does:
  #
  #   # config/routes.rb
  #   mount Reqcord::Web => "/api-docs" if Rails.env.development?
  #
  # `/api-docs` renders the OpenAPI document with Scalar; every other path is
  # a file from the output directory (`dataset.json`, `postman/collection.json`,
  # the Markdown pages, the cURL scripts). Nothing is generated on request —
  # run `bin/rails reqcord:generate` first.
  class Web
    SCALAR_SCRIPT = "https://cdn.jsdelivr.net/npm/@scalar/api-reference"
    OPENAPI_PATH = "openapi/openapi.json"

    class << self
      # `mount Reqcord::Web => "/api-docs"` calls the class itself.
      def call(env)
        app.call(env)
      end

      def app
        @app ||= new
      end
    end

    def initialize(root: nil)
      @root = root
    end

    def call(env)
      path = Rack::Utils.unescape_path(env["PATH_INFO"].to_s)

      return index(env) if path.empty? || path == "/"

      file = resolve(path)

      return not_found unless file

      [200, { "content-type" => content_type(file) }, [File.binread(file)]]
    end

    private

    def root
      Pathname(@root || Reqcord.configuration.output_directory).expand_path
    end

    def index(env)
      html = File.exist?(root.join(OPENAPI_PATH)) ? scalar_page(env) : empty_page(env)

      [200, { "content-type" => "text/html; charset=utf-8" }, [html]]
    end

    # The path traversal guard: whatever the request says, the file must be
    # inside the output directory.
    def resolve(path)
      candidate = root.join(path.delete_prefix("/")).expand_path

      return nil unless candidate.to_s.start_with?("#{root}/")
      return nil unless candidate.file?

      candidate.to_s
    end

    def content_type(file)
      case File.extname(file)
      when ".md" then "text/markdown; charset=utf-8"
      when ".sh" then "text/plain; charset=utf-8"
      else Rack::Mime.mime_type(File.extname(file), "application/octet-stream")
      end
    end

    def not_found
      [404, { "content-type" => "text/plain" }, ["Not Found"]]
    end

    # Absolute links: the page is served at the mount point itself, so a
    # relative `openapi/…` would resolve one level too high.
    def base(env)
      env["SCRIPT_NAME"].to_s.chomp("/")
    end

    def scalar_page(env)
      <<~HTML
        <!doctype html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>API Reference</title>
          </head>
          <body>
            <script id="api-reference" data-url="#{base(env)}/#{OPENAPI_PATH}"></script>
            <script src="#{SCALAR_SCRIPT}"></script>
          </body>
        </html>
      HTML
    end

    def empty_page(env)
      <<~HTML
        <!doctype html>
        <html>
          <head><meta charset="utf-8"><title>Reqcord</title></head>
          <body style="font-family: system-ui, sans-serif; max-width: 40rem; margin: 4rem auto; line-height: 1.5">
            <h1>No documentation generated yet</h1>
            <p>Reqcord serves the files under <code>#{root}</code>. Generate them from your test suite:</p>
            <pre>bin/rails reqcord:generate</pre>
            <p>Then reload this page: the OpenAPI document is rendered here with Scalar, and
            <a href="#{base(env)}/dataset.json">dataset.json</a>,
            <a href="#{base(env)}/postman/collection.json">postman/collection.json</a> and the Markdown pages are served alongside it.</p>
          </body>
        </html>
      HTML
    end
  end
end

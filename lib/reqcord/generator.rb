# frozen_string_literal: true

require "open3"
require "shellwords"
require "securerandom"

module Reqcord
  # Runs the test suite in a subprocess with capture enabled, then turns the
  # captured exchanges into documentation. Route collection happens here, in a
  # process that already has the application booted.
  class Generator
    def self.call(
      resources: [],
      version: nil
    )
      new(
        resources: resources,
        version: version
      ).call
    end

    def initialize(resources:, version:, configuration: Reqcord.configuration)
      @resources = Array(resources).map(&:to_s)
      @version = version&.to_s
      @configuration = configuration
    end

    def call
      validate!

      routes = collect_routes

      capture_file = build_capture_file

      run_tests(capture_file)

      exchanges =
        read_exchanges(capture_file)

      dataset =
        build_dataset(
          routes,
          exchanges
        )

      report(exchanges, dataset)

      write_outputs(dataset)

      dataset
    ensure
      FileUtils.rm_f(capture_file) if capture_file
    end

    # Paths that were captured but belong to no documented route. Kept so the
    # run can say why a request did not turn into documentation.
    attr_reader :unmatched_paths

    # Exit status of the test run, so a caller can tell a fully green run
    # from documentation generated out of a partly failing suite.
    attr_reader :test_status

    def tests_passed?
      test_status.nil? || test_status.success?
    end

    # Routes seen in the table but not documentable, by reason (redirect,
    # mount). Set by collect_routes; exposed so a run can be reconciled.
    attr_accessor :skipped_routes

    # The command that runs the suite. An explicit `test.command` is used as
    # written (globs expanded, since no shell is involved); otherwise a runner
    # is built from `test.paths`: `bin/rails test` when the application has
    # one, a plain Ruby runner when it does not, `rspec` for request specs.
    def test_argv
      explicit = configuration.test_command
      return expand_globs(Shellwords.split(explicit)) if explicit

      paths = configuration.test_paths
      return %w[bin/rails test] if paths.empty?

      case configuration.test_framework.to_s
      when "rspec"
        ["rspec", *paths]
      else
        if configuration.root.join("bin", "rails").exist?
          ["bin/rails", "test", *paths]
        else
          ["ruby", "-Itest", "-e", "ARGV.each { |file| require File.expand_path(file) }", *test_files(paths)]
        end
      end
    end

    # Builds the dataset from exchanges that were captured earlier, without
    # running the suite again.
    def build_dataset(routes, exchanges)
      endpoints = {}
      @unmatched_paths = []

      # A route answering any verb is documented once per verb a test used.
      routes.each do |route|
        endpoints[[route, route.method]] = route.endpoint unless route.any_verb?
      end

      ordered_exchanges(exchanges).each do |raw_exchange|
        sanitized =
          Sanitizers::Sanitizer.call(
            raw_exchange,
            configuration: configuration
          )

        route = find_route(routes, sanitized)
        request = sanitized.fetch("request")

        unless route
          @unmatched_paths << "#{request['method']} #{request['path']}"
          next
        end

        verb = route.any_verb? ? request.fetch("method").to_s.upcase : route.method
        endpoint = endpoints[[route, verb]] ||= route.endpoint(method: verb)

        attach_exchange(endpoint, sanitized)
      end

      routes.select(&:any_verb?).each do |route|
        next if endpoints.keys.any? { |(seen, _verb)| seen == route }

        endpoints[[route, RouteCollector::ANY]] = route.endpoint
      end

      Dataset.new(
        endpoints: Dataset.fold_method_twins(endpoints.values)
      )
    end

    private

    attr_reader :resources,
                :version,
                :configuration

    # Silence here is the worst outcome: an empty page set looks the same
    # whether the API has no tests or the capture never ran.
    def report(exchanges, dataset)
      if exchanges.empty?
        Reqcord.warn("no request was captured")
        Reqcord.warn("  is reqcord in the :test group of your Gemfile, and does `test.command` run integration tests?")
        return
      end

      covered = dataset.curl_ready_endpoints.size
      uncovered = dataset.uncovered_endpoints.size
      matched = exchanges.size - unmatched_paths.size
      skipped = skipped_routes || {}
      skipped_total = skipped.values.sum

      Reqcord.log("captured #{exchanges.size} request(s), #{matched} matched a documented route")
      Reqcord.log("captured a successful 2xx request for #{covered} of #{dataset.endpoints.size} endpoint(s)")

      # Every route lands in exactly one bucket; the sum is the proof.
      Reqcord.log(
        "routes: #{dataset.endpoints.size + skipped_total} = " \
        "#{covered} documented + #{uncovered} uncovered + #{skipped_total} skipped"
      )

      if skipped_total.positive?
        reasons = skipped.map { |reason, count| "#{count} #{reason}" }.join(", ")
        Reqcord.log("skipped #{skipped_total} route(s) that cannot be documented: #{reasons}")
      end

      unless tests_passed?
        Reqcord.warn("the test run failed: routes exercised only by failing tests are listed as uncovered")
      end

      return if unmatched_paths.empty?

      shown = unmatched_paths.uniq.first(5)

      Reqcord.log("#{unmatched_paths.uniq.size} path(s) matched no documented route, for example:")
      shown.each { |path| Reqcord.log("  #{path}") }
    end

    FRAMEWORKS = %w[minitest rspec].freeze

    def validate!
      unless FRAMEWORKS.include?(configuration.test_framework.to_s)
        raise ConfigurationError,
              "unsupported test framework: #{configuration.test_framework.inspect}, " \
              "expected one of #{FRAMEWORKS.join(', ')}"
      end

      configuration.exporters.each { |name| Exporters.fetch(name) }

      nil
    end

    def collect_routes
      collector = RouteCollector.new(
        resources: resources,
        version: version,
        prefix: configuration.route_prefixes
      )

      routes = collector.call
      @skipped_routes = collector.skipped

      routes
    end

    # A directory means every *_test.rb (or *_spec.rb) beneath it.
    def test_files(paths)
      pattern = configuration.test_framework.to_s == "rspec" ? "*_spec.rb" : "*_test.rb"

      paths.flat_map do |path|
        if configuration.root.join(path).directory?
          Dir.glob(File.join(path, "**", pattern), base: configuration.root.to_s).sort
        else
          expand_globs([path])
        end
      end
    end

    def expand_globs(args)
      args.flat_map do |arg|
        next [arg] unless arg.match?(/[*?\[{]/)

        matches = Dir.glob(arg, base: configuration.root.to_s).sort
        matches.empty? ? [arg] : matches
      end
    end

    def build_capture_file
      Reqcord.root.join(
        "tmp",
        "reqcord",
        "#{SecureRandom.hex(12)}.ndjson"
      ).to_s
    end

    def run_tests(capture_file)
      FileUtils.mkdir_p(
        File.dirname(capture_file)
      )

      env = {
        "REQCORD_CAPTURE" => "1",
        "REQCORD_CAPTURE_FILE" => capture_file
      }

      command = test_argv

      Reqcord.log("running #{Shellwords.join(command)}")

      # Streamed rather than captured: a long suite should print as it runs.
      status =
        Open3.popen2e(
          env,
          *command,
          chdir: Reqcord.root.to_s
        ) do |stdin, output, wait_thread|
          stdin.close

          output.each_line { |line| $stdout.print(line) }

          wait_thread.value
        end

      @test_status = status

      return if status.success?

      if configuration.strict_tests?
        raise GenerationError,
              "Test suite failed while generating Reqcord documentation (test.strict is on)"
      end

      # A red suite still tells the truth about the requests that passed;
      # dropping everything would hide the docs behind an unrelated failure.
      Reqcord.warn("test run exited with status #{status.exitstatus}; documenting what it captured anyway")
      Reqcord.warn("  set test.strict: true (or REQCORD_STRICT=1) to abort on a failing suite")
    end

    def read_exchanges(capture_file)
      return [] unless File.exist?(capture_file)

      File.readlines(capture_file)
          .filter_map do |line|
            line = line.strip

            next if line.empty?

            begin
              JSON.parse(line)
            rescue JSON::ParserError
              Reqcord.warn("skipping malformed capture line")
              nil
            end
          end
    end

    def find_route(routes, exchange)
      request = exchange.fetch("request")
      method = request.fetch("method")
      path = request.fetch("path")

      routes.find { |route| route.matches?(method, path) }
    rescue StandardError => e
      raise GenerationError, "could not match #{method} #{path} against the route table: #{e.message}"
    end

    # Test suites run in random order, and "the first example captured" is
    # what every page leads with. Ordering by where the test lives makes the
    # output a function of the code, so regenerating never produces a diff
    # by itself. Requests inside one test keep their execution order.
    def ordered_exchanges(exchanges)
      exchanges.each_with_index.sort_by do |exchange, index|
        source = exchange["source"] || {}

        [source["file"].to_s, source["line"].to_i, source["test"].to_s, index]
      end.map(&:first)
    end

    def attach_exchange(endpoint, exchange)
      request_data = exchange.fetch("request")
      response_data = exchange.fetch("response")
      source = normalize_source(exchange["source"])
      status = response_data.fetch("status")

      request =
        RequestExample.new(
          name: example_name(source),
          method: request_data.fetch("method"),
          # The concrete path, not the route pattern: the cURL must be runnable.
          path: request_data.fetch("path"),
          path_params: request_data["path_params"] || {},
          query_params: request_data["query_params"] || {},
          headers: request_data["headers"] || {},
          body: request_data["body"],
          content_type: request_data["content_type"],
          response_status: status,
          source: source
        )

      response =
        ResponseExample.new(
          name: example_name(source),
          status: status,
          headers: response_data["headers"] || {},
          body: response_data["body"],
          content_type: response_data["content_type"],
          source: source
        )

      endpoint.add_exchange(
        request: request,
        response: response
      )
    end

    # "test_creates_customer" -> "Creates Customer"
    def example_name(source)
      test = source["test"].to_s.sub(/\Atest_/, "")

      test.empty? ? nil : Support.titleize(test)
    end

    def normalize_source(source)
      source = (source || {}).transform_keys(&:to_s)
      file = source["file"].to_s
      prefix = "#{Reqcord.root}/"

      source["file"] = file.delete_prefix(prefix) unless file.empty?
      source.compact
    end

    def write_outputs(dataset)
      output = configuration.output_directory

      FileUtils.mkdir_p(output)

      written = [dataset.write(output.join("dataset.json"))]

      configuration.exporters.each do |name|
        written.concat(
          Exporters.fetch(name).call(
            dataset: dataset,
            output_dir: output,
            configuration: configuration
          )
        )
      end

      written
    end
  end
end

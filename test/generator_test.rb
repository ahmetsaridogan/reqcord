# frozen_string_literal: true

require_relative "test_helper"

class GeneratorTest < Minitest::Test
  include Reqcord::TestHelpers

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE
  end

  def generator(root, resources: [], version: nil, yaml: nil)
    Reqcord::Generator.new(
      resources: resources,
      version: version,
      configuration: configuration_for(root, yaml)
    )
  end

  def build(root, exchanges, **options)
    generator(root, **options).build_dataset(customer_routes, exchanges)
  end

  def test_attaches_a_capture_to_its_route
    Dir.mktmpdir do |root|
      dataset = build(root, [exchange])
      endpoint = dataset.documented_endpoints.single

      assert_equal "POST /api/v2/customers", endpoint.key
      assert_equal "Create Customer", endpoint.name
      assert_equal 201, endpoint.response_examples.first.status
      assert_equal "Creates Customer", endpoint.request_examples.first.name
    end
  end

  def test_undocumented_routes_stay_in_the_dataset
    Dir.mktmpdir do |root|
      dataset = build(root, [exchange])

      assert_operator dataset.endpoints.size, :>, dataset.documented_endpoints.size
      refute_empty dataset.endpoints.reject(&:documented?)
    end
  end

  def test_examples_are_sanitized_before_reaching_the_dataset
    Dir.mktmpdir do |root|
      endpoint = build(root, [exchange]).documented_endpoints.single
      example = endpoint.request_examples.first

      assert_equal "Bearer {{token}}", example.headers["Authorization"]
      refute endpoint.response_examples.first.headers.key?("X-Request-Id")
    end
  end

  def test_keeps_the_concrete_path_so_curl_is_runnable
    Dir.mktmpdir do |root|
      member = exchange("request" => { "method" => "GET", "path" => "/api/v2/customers/42", "body" => nil }, "response" => { "status" => 200 })
      endpoint = build(root, [member]).documented_endpoints.single

      assert_equal "/api/v2/customers/:id", endpoint.path
      assert_equal "/api/v2/customers/42", endpoint.request_examples.first.path
    end
  end

  def test_several_statuses_land_on_one_endpoint
    Dir.mktmpdir do |root|
      exchanges = [
        exchange,
        exchange("response" => { "status" => 401, "body" => { "error" => "Unauthorized" } }),
        exchange("response" => { "status" => 422, "body" => { "errors" => { "email" => ["taken"] } } })
      ]

      endpoint = build(root, exchanges).documented_endpoints.single

      assert_equal [201, 401, 422], endpoint.responses_by_status.keys
    end
  end

  def test_captures_without_a_matching_route_are_ignored_but_reported
    Dir.mktmpdir do |root|
      subject = generator(root)
      dataset = subject.build_dataset(customer_routes, [exchange("request" => { "path" => "/api/v2/unknown" })])

      assert_empty dataset.documented_endpoints
      assert_equal ["POST /api/v2/unknown"], subject.unmatched_paths
    end
  end

  def test_resource_filter_narrows_the_route_surface
    Dir.mktmpdir do |root|
      routes = customer_routes(only: ["surveys"])
      dataset = generator(root).build_dataset(routes, [exchange])

      assert_equal ["surveys"], dataset.endpoints.map(&:resource).uniq
      assert_empty dataset.documented_endpoints
    end
  end

  def test_accepts_the_supported_test_frameworks
    Dir.mktmpdir do |root|
      %w[minitest rspec].each do |framework|
        subject = generator(root, yaml: "test:\n  framework: #{framework}\n")

        assert_nil subject.send(:validate!)
      end
    end
  end

  def test_rejects_an_unsupported_test_framework
    Dir.mktmpdir do |root|
      subject = generator(root, yaml: "test:\n  framework: cucumber\n")

      error = assert_raises(Reqcord::ConfigurationError) { subject.send(:validate!) }

      assert_match(/unsupported test framework/, error.message)
    end
  end

  def test_rejects_an_unknown_exporter
    Dir.mktmpdir do |root|
      subject = generator(root, yaml: "exporters:\n  - openapi\n")

      error = assert_raises(Reqcord::ConfigurationError) { subject.send(:validate!) }

      assert_match(/unknown exporter/, error.message)
    end
  end

  # `via: :all` is documented once per verb the tests actually used.
  def test_an_any_verb_route_is_documented_per_captured_verb
    Dir.mktmpdir do |root|
      exchanges = %w[GET DELETE].map do |verb|
        exchange("request" => { "method" => verb, "path" => "/anything", "body" => nil }, "response" => { "status" => 200 })
      end

      dataset = generator(root).build_dataset(mixed_routes, exchanges)
      documented = dataset.documented_endpoints.select { |endpoint| endpoint.path == "/anything" }

      assert_equal %w[DELETE GET], documented.map(&:method).sort
      assert_equal ["ANY"], generator(root).build_dataset(mixed_routes, []).endpoints.select { |endpoint| endpoint.path == "/anything" }.map(&:method)
    end
  end

  def test_the_report_reconciles_every_route_into_one_bucket
    Dir.mktmpdir do |root|
      subject = generator(root)
      dataset = subject.build_dataset(customer_routes, [exchange])
      subject.skipped_routes = { "redirect" => 1, "mount" => 1 }

      stdout, = capture_io { subject.send(:report, [exchange], dataset) }

      assert_includes stdout, "routes: #{dataset.endpoints.size + 2} = 1 documented + #{dataset.endpoints.size - 1} uncovered + 2 skipped"
      assert_includes stdout, "skipped 2 route(s) that cannot be documented: 1 redirect, 1 mount"
    end
  end

  def test_the_report_flags_a_failing_test_run
    Dir.mktmpdir do |root|
      subject = generator(root, yaml: "test:\n  command: #{RbConfig.ruby} -e exit(3)\n")
      dataset = subject.build_dataset(customer_routes, [exchange])

      capture_io { subject.send(:run_tests, File.join(root, "capture.ndjson")) }
      _, stderr = capture_io { subject.send(:report, [exchange], dataset) }

      assert_includes stderr, "the test run failed"
    end
  end

  # --- how the suite gets run --------------------------------------------

  def test_a_failing_suite_still_documents_what_it_captured
    Dir.mktmpdir do |root|
      subject = generator(root, yaml: "test:\n  command: #{RbConfig.ruby} -e exit(3)\n")

      _, stderr = capture_io { subject.send(:run_tests, File.join(root, "capture.ndjson")) }

      refute subject.tests_passed?
      assert_equal 3, subject.test_status.exitstatus
      assert_includes stderr, "test run exited with status 3; documenting what it captured anyway"
      assert_includes stderr, "test.strict"
    end
  end

  def test_a_strict_run_aborts_on_a_failing_suite
    Dir.mktmpdir do |root|
      subject = generator(root, yaml: "test:\n  strict: true\n  command: #{RbConfig.ruby} -e exit(3)\n")

      error = assert_raises(Reqcord::GenerationError) do
        capture_io { subject.send(:run_tests, File.join(root, "capture.ndjson")) }
      end

      assert_match(/Test suite failed/, error.message)
    end
  end

  def test_a_green_suite_passes
    Dir.mktmpdir do |root|
      subject = generator(root, yaml: "test:\n  command: #{RbConfig.ruby} -e exit(0)\n")

      capture_io { subject.send(:run_tests, File.join(root, "capture.ndjson")) }

      assert subject.tests_passed?
    end
  end

  def with_test_files(root, *files)
    files.each do |file|
      FileUtils.mkdir_p(File.dirname(File.join(root, file)))
      File.write(File.join(root, file), "")
    end
  end

  def test_without_configuration_the_rails_runner_is_used
    Dir.mktmpdir do |root|
      assert_equal %w[bin/rails test], generator(root).test_argv
    end
  end

  def test_an_explicit_command_is_used_as_written_with_globs_expanded
    Dir.mktmpdir do |root|
      with_test_files(root, "test/api/b_test.rb", "test/api/a_test.rb")
      subject = generator(root, yaml: "test:\n  command: bin/rails test test/api/*_test.rb\n")

      assert_equal %w[bin/rails test test/api/a_test.rb test/api/b_test.rb], subject.test_argv
    end
  end

  def test_a_directory_runs_through_bin_rails_when_the_app_has_one
    Dir.mktmpdir do |root|
      with_test_files(root, "bin/rails", "test/integration/x_test.rb")
      subject = generator(root, yaml: "test:\n  paths:\n    - test/integration\n")

      assert_equal %w[bin/rails test test/integration], subject.test_argv
    end
  end

  # A one-file app has no bin/rails; every test file is required in turn.
  def test_a_directory_runs_through_a_ruby_runner_otherwise
    Dir.mktmpdir do |root|
      with_test_files(root, "test/integration/users_test.rb", "test/integration/customers_test.rb", "test/integration/helper.rb")
      subject = generator(root, yaml: "test:\n  paths:\n    - test/integration\n")

      argv = subject.test_argv

      assert_equal %w[ruby -Itest -e], argv.first(3)
      assert_equal %w[test/integration/customers_test.rb test/integration/users_test.rb], argv.last(2)
    end
  end

  def test_rspec_paths_go_straight_to_rspec
    Dir.mktmpdir do |root|
      subject = generator(root, yaml: "test:\n  framework: rspec\n  paths:\n    - spec/requests\n")

      assert_equal %w[rspec spec/requests], subject.test_argv
    end
  end

  def test_reads_exchanges_from_the_capture_file
    Dir.mktmpdir do |root|
      path = File.join(root, "capture.ndjson")
      File.write(path, "#{JSON.generate(exchange)}\n\n{ not json }\n")

      subject = generator(root)
      exchanges = subject.send(:read_exchanges, path)

      assert_equal 1, exchanges.size
      assert_equal "/api/v2/customers", exchanges.first.dig("request", "path")
    end
  end
end

# Readability helper for the assertions above.
module SingleElement
  def single
    raise "expected exactly one element, got #{size}" unless size == 1

    first
  end
end
Array.prepend(SingleElement)

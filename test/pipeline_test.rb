# frozen_string_literal: true

require_relative "test_helper"
require "open3"

# Drives the whole pipeline through the dummy application: boot, route
# collection, a real test run in a subprocess, capture, sanitization and
# export. Run out of process so booting Rails does not leak into this suite.
class PipelineTest < Minitest::Test
  include Reqcord::TestHelpers

  ROOT = File.expand_path("..", __dir__)
  DUMMY = File.join(ROOT, "test", "dummy")

  # Generating once per class keeps the suite fast: the assertions below only
  # read the result.
  class << self
    def generated
      @generated ||= begin
        output = Dir.mktmpdir("reqcord-pipeline")
        Minitest.after_run { FileUtils.rm_rf(output) }

        stdout, status = Open3.capture2e(
          { "REQCORD_OUTPUT" => output },
          RbConfig.ruby,
          File.join(DUMMY, "generate.rb"),
          chdir: DUMMY
        )

        { output: output, stdout: stdout, status: status }
      end
    end
  end

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE

    result = self.class.generated

    @output = result[:output]
    @stdout = result[:stdout]
    @status = result[:status]
  end

  def document(*parts)
    File.read(File.join(@output, *parts))
  end

  def test_the_run_succeeds_and_reports_coverage
    assert @status.success?, @stdout
    assert_includes @stdout, "16 runs, 16 assertions, 0 failures"
    assert_includes @stdout, "endpoints=14 documented=13"
  end

  # Every route lands in exactly one bucket, and the report proves the sum.
  def test_the_report_reconciles_the_route_table
    assert_includes @stdout, "routes: 16 = 13 documented + 1 uncovered + 2 skipped"
    assert_includes @stdout, "skipped 2 route(s) that cannot be documented: 1 redirect, 1 mount"
  end

  def test_routes_beyond_resources_get_their_own_pages
    assert_path_exists File.join(@output, "api", "home", "list.md")
    assert_path_exists File.join(@output, "api", "echo", "any-get.md")
    assert_path_exists File.join(@output, "api", "echo", "any-post.md")
    assert_path_exists File.join(@output, "api", "anything", "any.md")
    assert_path_exists File.join(@output, "api", "items", "show.md")
    assert_path_exists File.join(@output, "api", "files", "show.md")
    assert_path_exists File.join(@output, "api", "admin", "customers", "list.md")
    assert_path_exists File.join(@output, "billing", "invoices", "list.md")
  end

  def test_patch_and_put_share_one_page
    page = document("api", "carts", "update.md")

    assert_includes page, "`PATCH /api/cart` (also `PUT`)"
    assert_includes page, "cart%5Bcoupon%5D=SAVE10"
    refute_path_exists File.join(@output, "api", "carts", "update-2.md")
  end

  def test_pages_beyond_resources_are_titled_sensibly
    assert_includes document("api", "home", "list.md"), "# Home"
    assert_includes document("api", "carts", "update.md"), "# Update Cart"
    assert_includes document("api", "admin", "customers", "list.md"), "Namespace: `api/admin`"
  end

  def test_dataset_is_written
    data = JSON.parse(document("dataset.json"))

    assert_equal 2, data["schema_version"]
    assert_includes data["endpoints"].map { |endpoint| "#{endpoint['method']} #{endpoint['path']}" },
                    "POST /api/v2/customers"
  end

  def test_pages_are_written_per_resource
    assert_path_exists File.join(@output, "README.md")
    assert_path_exists File.join(@output, "api", "v2", "customers","create.md")
    assert_path_exists File.join(@output, "api", "v2", "customers","show.md")
    assert_path_exists File.join(@output, "api", "v2", "customers","list.md")
  end

  def test_every_response_status_reaches_the_page
    page = document("api", "v2", "customers","create.md")

    assert_includes page, "### 201 Created"
    assert_includes page, "### 401 Unauthorized"
    # "Unprocessable Content" on Rack >= 3.1, "Unprocessable Entity" before.
    assert_includes page, "### 422 #{Rack::Utils::HTTP_STATUS_CODES[422]}"
  end

  def test_credentials_never_reach_the_documentation
    pages = Dir.glob(File.join(@output, "**", "*")).select { |path| File.file?(path) }

    refute_empty pages

    pages.each do |path|
      content = File.read(path)

      refute_includes content, "secret-token", path
      refute_includes content, "hunter2", path
    end

    assert_includes document("api", "v2", "customers","create.md"), "Bearer {{token}}"
    assert_includes document("api", "v2", "customers","create.md"), "{{password}}"
  end

  def test_generated_curl_is_runnable
    page = document("api", "v2", "customers","show.md")

    assert_includes page, %(--url "http://localhost:3000/api/v2/customers/42")
    refute_includes page, "/api/v2/customers/:id\""
  end

  # The gap belongs in the index, not in a page with nothing on it.
  def test_uncovered_routes_are_reported_without_writing_an_empty_page
    assert_includes document("README.md"), "## No Successful Request Captured"
    assert_includes document("README.md"), "`POST /api/v2/customers/:id/activate`"

    refute_path_exists File.join(@output, "api", "v2", "customers","activate.md")
  end

  def test_routes_outside_the_prefix_are_ignored
    refute_includes document("README.md"), "/health"
  end

  def test_capture_file_is_cleaned_up
    assert_empty Dir.glob(File.join(DUMMY, "tmp", "reqcord", "*"))
  end

  def test_an_ordinary_test_run_captures_nothing
    stdout, status = Open3.capture2e(
      RbConfig.ruby,
      File.join(DUMMY, "integration_tests.rb"),
      chdir: DUMMY
    )

    assert status.success?, stdout
    assert_empty Dir.glob(File.join(DUMMY, "tmp", "reqcord", "*"))
  end
end

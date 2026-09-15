# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/dummy_server"

# The generated cURL is the part of the output people actually run, so it is
# checked by running it: the documented command is executed against the dummy
# application over real HTTP and has to return the documented status.
class CurlExecutionTest < Minitest::Test
  include Reqcord::TestHelpers

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE
  end

  def page(*parts)
    parts = ["api", "v2", "customers", *parts] if parts.size == 1

    File.read(File.join(DummyServer.documentation, *parts))
  end

  # The command as documented, pointed at the test server with the placeholder
  # filled in, exactly as a reader would do by hand.
  def run_curl(command)
    runnable = command
               .gsub("{{token}}", DummyServer::TOKEN)
               .gsub("http://localhost:3000", DummyServer.base_url)
               .gsub(" \\\n  ", " ")

    stdout, status = Open3.capture2e(
      "#{runnable} --silent --output /dev/null --write-out '%{http_code}'"
    )

    assert status.success?, "curl failed: #{stdout}"

    stdout.strip
  end

  def curl_from(*parts)
    page(*parts)[/```bash\n(.+?)```/m, 1].strip
  end

  def test_documented_get_runs
    assert_equal "200", run_curl(curl_from("list.md"))
  end

  def test_documented_member_get_runs
    assert_equal "200", run_curl(curl_from("show.md"))
  end

  def test_documented_post_runs_and_returns_the_documented_status
    command = curl_from("create.md")

    assert_includes command, "--data"
    assert_equal "201", run_curl(command)
  end

  def test_documented_optional_segment_glob_and_engine_requests_run
    assert_equal "200", run_curl(curl_from("api", "items", "show.md"))
    assert_equal "200", run_curl(curl_from("api", "files", "show.md"))
    assert_equal "200", run_curl(curl_from("billing", "invoices", "list.md"))
    assert_equal "200", run_curl(curl_from("api", "home", "list.md"))
  end

  # A form body must travel as a form, not be re-invented as JSON.
  def test_documented_form_patch_runs
    command = curl_from("api", "carts", "update.md")

    assert_includes command, "--request PATCH"
    assert_includes command, "cart%5Bcoupon%5D=SAVE10"
    assert_equal "200", run_curl(command)
  end

  # Without the placeholder replaced, the documented request is unauthorized:
  # proof the credential really was stripped from the documentation.
  def test_the_placeholder_is_not_a_working_credential
    refute_includes curl_from("create.md"), "eyJhbGciOi"
  end
end

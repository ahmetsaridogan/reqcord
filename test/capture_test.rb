# frozen_string_literal: true

require_relative "test_helper"

class CaptureTest < Minitest::Test
  include Reqcord::TestHelpers

  def with_capture(path)
    ENV["REQCORD_CAPTURE"] = "1"
    ENV["REQCORD_CAPTURE_FILE"] = path
    yield
  ensure
    ENV.delete("REQCORD_CAPTURE")
    ENV.delete("REQCORD_CAPTURE_FILE")
  end

  def test_capture_is_opt_in
    refute Reqcord::Capture.enabled?

    with_capture("/tmp/reqcord-test.ndjson") do
      assert Reqcord::Capture.enabled?
    end
  end

  def test_the_flag_alone_is_not_enough
    ENV["REQCORD_CAPTURE"] = "1"

    refute Reqcord::Capture.enabled?
  ensure
    ENV.delete("REQCORD_CAPTURE")
  end

  def test_nothing_is_written_while_capture_is_off
    Dir.mktmpdir do |root|
      path = File.join(root, "capture.ndjson")
      Reqcord::Capture::Collector.write(exchange)

      refute File.exist?(path)
    end
  end

  def test_writes_one_json_line_per_exchange
    Dir.mktmpdir do |root|
      path = File.join(root, "nested", "capture.ndjson")

      with_capture(path) do
        Reqcord::Capture::Collector.write(exchange)
        Reqcord::Capture::Collector.write(exchange)
      end

      lines = File.readlines(path)

      assert_equal 2, lines.size
      assert_equal "/api/v2/customers", JSON.parse(lines.first).dig("request", "path")
    end
  end

  # Parallel test workers append to the same file; the lock has to keep their
  # lines whole.
  def test_concurrent_writers_do_not_interleave_lines
    Dir.mktmpdir do |root|
      path = File.join(root, "capture.ndjson")

      with_capture(path) do
        pids = 4.times.map do
          fork do
            25.times { |index| Reqcord::Capture::Collector.write(exchange("source" => { "test" => "test_#{index}" })) }
          end
        end

        pids.each { |pid| Process.wait(pid) }
      end

      lines = File.readlines(path).map(&:strip).reject(&:empty?)

      assert_equal 100, lines.size
      lines.each { |line| JSON.parse(line) }
    end
  end

  def test_test_context_is_per_thread
    Reqcord::Capture::TestContext.current = { test: "test_one" }

    assert_equal({}, Thread.new { Reqcord::Capture::TestContext.current }.value)
    assert_equal "test_one", Reqcord::Capture::TestContext.current[:test]
  ensure
    Reqcord::Capture::TestContext.clear
  end

  def test_test_context_clears
    Reqcord::Capture::TestContext.current = { test: "test_one" }
    Reqcord::Capture::TestContext.clear

    assert_empty Reqcord::Capture::TestContext.current
  end
end

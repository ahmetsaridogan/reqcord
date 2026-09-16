# frozen_string_literal: true

require_relative "test_helper"
require "open3"

class CheckTest < Minitest::Test
  include Reqcord::TestHelpers

  def tree(root, files)
    files.each do |path, content|
      full = File.join(root, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, content)
    end
  end

  def test_identical_trees_are_clean
    Dir.mktmpdir do |expected|
      Dir.mktmpdir do |actual|
        files = { "README.md" => "# API\n", "api/v1/customers/create.md" => "# Create\n", "dataset.json" => "{}\n" }
        tree(expected, files)
        tree(actual, files)

        result = Reqcord::Check.compare(expected: expected, actual: actual)

        assert result.clean?
        assert_empty result.lines
      end
    end
  end

  def test_reports_added_removed_and_changed_files
    Dir.mktmpdir do |expected|
      Dir.mktmpdir do |actual|
        tree(expected, "README.md" => "old\n", "gone.md" => "x\n", "same.md" => "s\n")
        tree(actual, "README.md" => "new\n", "fresh/new.md" => "y\n", "same.md" => "s\n")

        result = Reqcord::Check.compare(expected: expected, actual: actual)

        refute result.clean?
        assert_equal ["fresh/new.md"], result.added
        assert_equal ["gone.md"], result.removed
        assert_equal ["README.md"], result.changed
        assert_equal ["A fresh/new.md", "D gone.md", "M README.md"], result.lines
      end
    end
  end

  def test_a_missing_committed_directory_reports_everything_as_added
    Dir.mktmpdir do |actual|
      tree(actual, "README.md" => "x\n")

      result = Reqcord::Check.compare(expected: File.join(actual, "does-not-exist"), actual: actual)

      assert_equal ["README.md"], result.added
    end
  end

  def test_the_configuration_copy_writes_elsewhere_and_leaves_the_original_alone
    Dir.mktmpdir do |root|
      original = configuration_for(root)
      copy = original.with_output_directory("/tmp/elsewhere")

      assert_equal Pathname("/tmp/elsewhere"), copy.output_directory
      assert_equal Pathname(File.join(root, "docs/api")), original.output_directory
      assert_equal original.exporters, copy.exporters
    end
  end
end

# The whole thing against the dummy application: generate, check (clean),
# edit a page, check again (dirty).
class CheckPipelineTest < Minitest::Test
  DUMMY = File.expand_path("dummy", __dir__)

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE
  end

  def run_script(script, output)
    Open3.capture2e({ "REQCORD_OUTPUT" => output }, RbConfig.ruby, script, chdir: DUMMY)
  end

  def test_check_is_clean_after_generate_and_dirty_after_an_edit
    Dir.mktmpdir do |output|
      _, status = run_script("generate.rb", output)
      assert status.success?

      stdout, status = run_script("check.rb", output)
      assert status.success?, stdout
      assert_includes stdout, "up to date"

      File.write(File.join(output, "api", "v2", "customers", "create.md"), "edited by hand\n")
      FileUtils.rm(File.join(output, "curl", "api", "v2", "customers", "show.sh"))
      File.write(File.join(output, "stray.md"), "not generated\n")

      stdout, status = run_script("check.rb", output)
      refute status.success?
      assert_includes stdout, "out of date"
      assert_includes stdout, "M api/v2/customers/create.md"
      assert_includes stdout, "A curl/api/v2/customers/show.sh"
      assert_includes stdout, "D stray.md"
    end
  end
end

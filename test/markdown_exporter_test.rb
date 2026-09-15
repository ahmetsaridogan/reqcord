# frozen_string_literal: true

require_relative "test_helper"

class MarkdownExporterTest < Minitest::Test
  include Reqcord::TestHelpers

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE
  end

  def export(root)
    configuration = configuration_for(root)

    exchanges = [
      exchange,
      exchange("response" => { "status" => 401, "body" => { "error" => "Unauthorized" } }),
      exchange(
        "request" => { "body" => { "customer" => { "email" => "taken@example.com" } } },
        "response" => { "status" => 422, "body" => { "errors" => { "email" => ["has already been taken"] } } },
        "source" => { "test" => "test_rejects_duplicate_email" }
      ),
      exchange(
        "request" => { "method" => "GET", "path" => "/api/v2/customers/42", "body" => nil, "path_params" => { "id" => "42" } },
        "response" => { "status" => 200, "body" => { "id" => 42 } },
        "source" => { "test" => "test_shows_customer" }
      )
    ]

    dataset = Reqcord::Generator
              .new(resources: [], version: nil, configuration: configuration)
              .build_dataset(customer_routes, exchanges)

    files = Reqcord::Exporters::Markdown.call(
      dataset: dataset,
      output_dir: configuration.output_directory,
      configuration: configuration
    )

    [configuration.output_directory, files]
  end

  def test_writes_a_page_per_endpoint_under_its_resource
    Dir.mktmpdir do |root|
      output, files = export(root)
      relative = files.map { |file| Pathname(file).relative_path_from(output).to_s }

      assert_equal(
        %w[README.md api/v2/customers/index.md api/v2/customers/create.md api/v2/customers/show.md].sort,
        relative.sort
      )
      assert files.all? { |file| File.exist?(file) }
    end
  end

  def test_endpoint_page_documents_the_whole_exchange
    Dir.mktmpdir do |root|
      output, = export(root)
      document = File.read(output.join("api", "v2", "customers","create.md"))

      assert_includes document, "# Create Customer"
      assert_includes document, "`POST /api/v2/customers`"
      assert_includes document, "| Authorization | `Bearer {{token}}` |"
      assert_includes document, "## Body Parameters"
      assert_includes document, "## Example Request"
      assert_includes document, "curl --request POST"
      assert_includes document, '--url "http://localhost:3000/api/v2/customers"'
      assert_includes document, "### 201 Created"
      assert_includes document, "### 401 Unauthorized"
      assert_includes document, "### 422 Unprocessable"
      refute_includes document, "eyJhbGciOi"
    end
  end

  def test_only_successful_requests_shape_the_parameters
    Dir.mktmpdir do |root|
      output, = export(root)
      document = File.read(output.join("api", "v2", "customers","create.md"))

      # The 201 request carried this address; the 422 request carried the
      # duplicate one, which describes what the API rejects, not what it takes.
      assert_includes document, "john@example.com"
      refute_includes document, "taken@example.com"
    end
  end

  def test_member_page_lists_path_parameters_and_a_runnable_curl
    Dir.mktmpdir do |root|
      output, = export(root)
      document = File.read(output.join("api", "v2", "customers","show.md"))

      assert_includes document, "## Path Parameters"
      assert_includes document, "| `id` | string | yes | `\"42\"` |"
      assert_includes document, '--url "http://localhost:3000/api/v2/customers/42"'
      refute_includes document, "/customers/:id\""
    end
  end

  def test_routes_without_examples_are_reported_as_gaps
    Dir.mktmpdir do |root|
      output, = export(root)
      index = File.read(output.join("README.md"))

      assert_includes index, "## No Successful Request Captured"
      assert_includes index, "`POST /api/v2/customers/:id/activate`"
      assert_includes index, "_(no successful request captured)_"
      refute output.join("api", "v2", "customers","activate.md").exist?
    end
  end

  def test_gap_pages_can_be_asked_for
    Dir.mktmpdir do |root|
      configuration = configuration_for(root, "output:\n  include_uncovered: true\n")
      dataset = Reqcord::Generator
                .new(resources: [], version: nil, configuration: configuration)
                .build_dataset(customer_routes, [exchange])

      Reqcord::Exporters::Markdown.call(dataset: dataset, output_dir: configuration.output_directory, configuration: configuration)

      page = configuration.output_directory.join("api", "v2", "customers", "activate.md")

      assert_path_exists page.to_s
      assert_includes File.read(page), "_No successful 2xx request was captured for this endpoint yet._"
    end
  end

  def test_index_links_resolve_to_written_files
    Dir.mktmpdir do |root|
      output, = export(root)
      links = File.read(output.join("README.md")).scan(/\]\(([^)]+)\)/).flatten

      refute_empty links
      links.each { |link| assert output.join(link).exist?, "missing #{link}" }
    end
  end

  def test_placeholders_are_explained_in_the_index
    Dir.mktmpdir do |root|
      output, = export(root)
      index = File.read(output.join("README.md"))

      assert_includes index, "## Placeholders"
      assert_includes index, "| Authorization | `Bearer {{token}}` |"
      assert_includes index, "Base URL: `http://localhost:3000`"
    end
  end
end

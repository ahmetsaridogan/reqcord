# frozen_string_literal: true

require_relative "test_helper"
require "open3"

# The published examples have to keep working: each one is generated into a
# temporary directory and checked, without touching the committed output.
class ExamplesTest < Minitest::Test
  include Reqcord::TestHelpers

  EXAMPLES = File.expand_path("../examples", __dir__)

  # Each Minitest example has an RSpec twin documenting the same application.
  PAIRS = { "test-app" => "spec-app", "complex-test-app" => "complex-spec-app" }.freeze

  # Credentials the example tests send; none may reach a generated file.
  SECRETS = %w[super-secret correct-horse-battery tok_live_9f8e7d6c].freeze

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE
  end

  def generate(example)
    output = Dir.mktmpdir("reqcord-#{example}")

    stdout, status = Open3.capture2e(
      { "REQCORD_OUTPUT" => output },
      RbConfig.ruby,
      "generate.rb",
      chdir: File.join(EXAMPLES, example)
    )

    [output, stdout, status]
  ensure
    @outputs ||= []
    @outputs << output
  end

  def teardown
    Array(@outputs).each { |output| FileUtils.rm_rf(output) }
  end

  # Every example generates, covers its whole route table, validates as a
  # Postman collection and leaks no credential.
  def assert_generates(name)
    output, stdout, status = generate(name)

    assert status.success?, stdout

    report = stdout.match(/routes: (\d+) = (\d+) documented \+ (\d+) uncovered \+ (\d+) skipped/)

    refute_nil report, stdout
    assert_equal report[1], report[2], "every route of #{name} should be covered by a test:\n#{stdout}"

    Dir.glob(File.join(output, "**", "*")).select { |path| File.file?(path) }.each do |path|
      content = File.read(path)

      SECRETS.each { |secret| refute_includes content, secret, path }
    end

    assert_path_exists File.join(output, "postman", "collection.json")

    openapi = JSON.parse(File.read(File.join(output, "openapi", "openapi.json")))

    assert_equal "3.1.0", openapi["openapi"]
    refute_empty openapi["paths"]

    [output, JSON.parse(File.read(File.join(output, "dataset.json")))]
  end

  def page(output, *parts)
    File.read(File.join(output, *parts))
  end

  def test_minitest_example
    output, data = assert_generates("test-app")
    create = page(output, "api", "v1", "customers", "create.md")

    # The two accepted values, from two passing tests; "inactive" was rejected.
    assert_includes create, %(| `customer.status` | string | yes | `"active"` \\| `"passive"` |)
    refute_includes create, "inactive"
    assert_includes create, "Bearer {{token}}"
    assert_includes create, "### 201 Created"
    assert_includes create, "### 422 #{Rack::Utils::HTTP_STATUS_CODES[422]}"
    assert_includes page(output, "api", "v1", "tasks", "update.md"), "(also `PUT`)"
    assert_equal 2, data["schema_version"]
    assert_includes data["endpoints"].map { |endpoint| endpoint["name"] }, "Create Customer"
  end

  def test_rspec_example
    _, data = assert_generates("spec-app")

    source = data["endpoints"]
             .find { |endpoint| endpoint["action"] == "create" && endpoint["resource"] == "customers" }
             .dig("request_examples", 0, "source")

    assert_equal "creates an active customer", source["test"]
    assert_includes source["file"], "customers_spec.rb"
  end

  def test_complex_example_documents_the_hard_cases
    output, data = assert_generates("complex-test-app")

    orders = page(output, "api", "v1", "orders", "create.md")
    assert_includes orders, "`order.line_items[].sku`"
    assert_includes orders, "`order.line_items[].quantity`"
    assert_includes orders, "`order.shipping_address.city`"
    assert_includes orders, "### 201 Created"
    assert_includes orders, "### 422 #{Rack::Utils::HTTP_STATUS_CODES[422]}"

    products = page(output, "api", "v1", "products", "list.md")
    assert_includes products, "| `filter.category` | string | no | `\"mugs\"` \\| `\"tea\"` |"
    assert_includes products, "| `sort` | string | no | `\"price_asc\"` \\| `\"price_desc\"` |"
    # Fixture names repeat across list responses; that must not read as a set.
    assert_includes products, "| `data[].category` | string | yes | `\"mugs\"` \\| `\"tea\"` |"
    refute_includes products, "`\"Stoneware Mug\"` \\|"

    login = page(output, "api", "v1", "auth", "login.md")
    assert_includes login, "# Login"
    assert_includes login, "| `password` | string | yes | `\"{{password}}\"` |"
    assert_includes login, "\"token\": \"{{token}}\""

    assert_includes page(output, "api", "v1", "profiles", "update.md"), "`PATCH /api/v1/profile` (also `PUT`)"
    assert_includes page(output, "api", "v1", "notes", "list.md"), "| `order_id` | string | yes |"
    assert_includes page(output, "api", "v1", "orders", "cancel.md"), "### 409 Conflict"

    checkout = page(output, "api", "v1", "carts", "checkout.md")
    assert_includes checkout, "# Checkout Cart"
    assert_includes checkout, "| `payment_method` | string | yes | `\"bank_transfer\"` \\| `\"card\"` |"
    assert_includes page(output, "api", "v1", "cart-items", "destroy.md"), "| `sku` | string | yes |"
    assert_includes page(output, "api", "v1", "admin", "products", "list.md"), "Namespace: `api/v1/admin`"
    assert_includes page(output, "api", "v1", "admin", "products", "list.md"), "{{api_key}}"
    assert_includes page(output, "api", "v1", "home", "list.md"), "# Home"

    assert_includes data["endpoints"].map { |endpoint| "#{endpoint['method']} #{endpoint['path']}" }, "GET /api/v2/products"

    collection = JSON.parse(page(output, "postman", "collection.json"))
    login_request = flatten(collection["item"]).find { |item| item["name"] == "Login" }

    assert_equal "urlencoded", login_request.dig("request", "body", "mode")
    assert_equal "noauth", login_request.dig("request", "auth", "type")
  end

  # Both frameworks must produce the same documented surface.
  def test_paired_examples_document_the_same_endpoints
    PAIRS.each do |minitest_example, rspec_example|
      minitest_output, = generate(minitest_example)
      rspec_output, = generate(rspec_example)

      assert_equal endpoint_keys(minitest_output), endpoint_keys(rspec_output), "#{minitest_example} vs #{rspec_example}"
    end
  end

  private

  def endpoint_keys(output)
    JSON.parse(File.read(File.join(output, "dataset.json")))["endpoints"]
        .map { |endpoint| "#{endpoint['method']} #{endpoint['path']}" }
        .sort
  end

  def flatten(items)
    items.flat_map { |item| item.key?("item") ? flatten(item["item"]) : [item] }
  end
end

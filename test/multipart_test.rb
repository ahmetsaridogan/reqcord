# frozen_string_literal: true

require_relative "test_helper"

# A file upload has no bytes to document: the name and type travel as a
# marker, and every renderer turns the marker into its own idiom.
class MultipartTest < Minitest::Test
  include Reqcord::TestHelpers

  AVATAR = Reqcord::FileValue.marker("avatar.png", "image/png")

  def setup
    skip "actionpack is not installed" unless ACTIONPACK_AVAILABLE
  end

  def upload_exchange(**overrides)
    exchange(
      "request" => {
        "headers" => { "Authorization" => "Bearer eyJhbGciOi", "Content-Type" => "multipart/form-data" },
        "content_type" => "multipart/form-data",
        "body" => { "customer" => { "name" => "Ada", "avatar" => AVATAR } }
      },
      **overrides
    )
  end

  def upload_request
    Reqcord::RequestExample.new(
      method: "POST",
      path: "/api/v2/customers",
      headers: { "Authorization" => "Bearer {{token}}", "Content-Type" => "multipart/form-data" },
      body: { "customer" => { "name" => "Ada", "avatar" => AVATAR } },
      content_type: "multipart/form-data",
      response_status: 201
    )
  end

  def dataset_for(root, exchanges = [upload_exchange])
    Reqcord::Generator
      .new(resources: [], version: nil, configuration: configuration_for(root))
      .build_dataset(customer_routes, exchanges)
  end

  def test_the_marker
    assert Reqcord::FileValue.file?(AVATAR)
    refute Reqcord::FileValue.file?({ "name" => "x" })
    assert_equal "avatar.png", Reqcord::FileValue.filename(AVATAR)
    assert_equal "avatar.png (image/png)", Reqcord::FileValue.describe(AVATAR)
    assert_equal({ "$file" => "a.txt" }, Reqcord::FileValue.marker("a.txt", nil))
    assert Reqcord::FileValue.any?("customer" => { "avatar" => AVATAR })
    refute Reqcord::FileValue.any?("customer" => { "name" => "Ada" })
  end

  def test_payload_treats_a_file_as_one_form_part
    request = upload_request

    assert Reqcord::Renderers::Payload.multipart?(request)
    assert_equal [["customer[name]", "Ada"], ["customer[avatar]", AVATAR]], Reqcord::Renderers::Payload.form_pairs(request)
    assert_equal({ "customer" => { "name" => "Ada", "avatar" => "avatar.png (image/png)" } },
                 Reqcord::Renderers::Payload.display_body(request))
  end

  # A body carrying a file is multipart even when the captured type says otherwise.
  def test_a_file_in_the_body_makes_the_request_multipart
    request = upload_request
    request.content_type = "application/x-www-form-urlencoded"

    assert Reqcord::Renderers::Payload.multipart?(request)
  end

  def test_curl_uses_form_parts_and_no_content_type_header
    command = Reqcord::Renderers::Curl.call(upload_request, base_url: "http://localhost:3000")

    assert_includes command, "--form 'customer[name]=Ada'"
    assert_includes command, "--form 'customer[avatar]=@avatar.png;type=image/png'"
    assert_includes command, %(--header "Authorization: Bearer {{token}}")
    refute_includes command, "Content-Type"
    refute_includes command, "--data"
  end

  def test_schema_types_the_upload_as_a_file
    schema = Reqcord::Schema.infer([{ "customer" => { "name" => "Ada", "avatar" => AVATAR } }])
    field = schema["customer.avatar"]

    assert_equal "file", field.type
    assert field.required?
    assert_equal ["avatar.png"], field.values
    refute field.enum?
    assert_nil schema["customer.avatar.$file"]
  end

  def test_the_markdown_page_names_the_file
    Dir.mktmpdir do |root|
      configuration = configuration_for(root)
      Reqcord::Exporters::Markdown.call(dataset: dataset_for(root), output_dir: configuration.output_directory, configuration: configuration)
      page = File.read(File.join(root, "docs", "api", "api", "v2", "customers", "create.md"))

      assert_includes page, "| `customer.avatar` | file | yes | `\"avatar.png\"` |"
      assert_includes page, "Sent as `multipart/form-data`"
      assert_includes page, %("avatar": "avatar.png (image/png)")
      assert_includes page, "--form 'customer[avatar]=@avatar.png;type=image/png'"
      refute_includes page, "$file"
    end
  end

  def test_postman_sends_formdata_with_a_file_part
    Dir.mktmpdir do |root|
      configuration = configuration_for(root)
      Reqcord::Exporters::Postman.call(dataset: dataset_for(root), output_dir: configuration.output_directory, configuration: configuration)
      collection = JSON.parse(File.read(File.join(root, "docs", "api", "postman", "collection.json")))
      request = flatten(collection["item"]).find { |item| item["name"] == "Create Customer" }["request"]

      assert_equal "formdata", request.dig("body", "mode")
      assert_includes request.dig("body", "formdata"), { "key" => "customer[name]", "value" => "Ada", "type" => "text" }
      assert_includes request.dig("body", "formdata"), { "key" => "customer[avatar]", "type" => "file", "src" => "avatar.png" }
    end
  end

  def test_openapi_describes_a_binary_multipart_body
    Dir.mktmpdir do |root|
      configuration = configuration_for(root)
      Reqcord::Exporters::Openapi.call(dataset: dataset_for(root), output_dir: configuration.output_directory, configuration: configuration)
      document = JSON.parse(File.read(File.join(root, "docs", "api", "openapi", "openapi.json")))
      body = document.dig("paths", "/api/v2/customers", "post", "requestBody", "content", "multipart/form-data")

      refute_nil body
      assert_equal({ "type" => "string", "format" => "binary" }, body.dig("schema", "properties", "customer", "properties", "avatar"))
      assert_equal "avatar.png", body.dig("example", "customer", "avatar")
    end
  end

  def test_the_dataset_keeps_the_marker_and_never_the_bytes
    Dir.mktmpdir do |root|
      data = dataset_for(root).to_h
      body = data[:endpoints].first[:request_examples].first[:body]

      assert_equal AVATAR, body.dig("customer", "avatar")
      assert_equal "file", data[:endpoints].first[:parameters][:body].find { |field| field[:path] == "customer.avatar" }[:type]
    end
  end

  private

  def flatten(items)
    items.flat_map { |item| item.key?("item") ? flatten(item["item"]) : [item] }
  end
end

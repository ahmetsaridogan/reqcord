# frozen_string_literal: true

require_relative "test_helper"

class SchemaTest < Minitest::Test
  include Reqcord::TestHelpers

  def infer(payloads)
    Reqcord::Schema.infer(payloads)
  end

  def test_describes_fields_by_path_and_type
    schema = infer([{ "user" => { "name" => "Ada", "age" => 36, "admin" => false } }])

    assert_equal %w[user.name user.age user.admin], schema.map(&:path)
    assert_equal "string", schema["user.name"].type
    assert_equal "integer", schema["user.age"].type
    assert_equal "boolean", schema["user.admin"].type
  end

  def test_a_field_missing_from_a_working_request_is_optional
    schema = infer([{ "name" => "Ada", "nickname" => "A" }, { "name" => "Linus" }])

    assert schema["name"].required?
    refute schema["nickname"].required?
  end

  # `GET /tasks` and `GET /tasks?status=open` both succeeded: `status` is
  # optional, even though every request that carried it was the same shape.
  def test_an_accepted_request_without_parameters_makes_them_all_optional
    schema = infer([{ "status" => "open" }, {}, nil])

    assert_equal ["status"], schema.map(&:path)
    refute schema["status"].required?
  end

  # The case this exists for: two passing tests send "active" and "passive",
  # a third sends "inactive" and is rejected, so it never reaches the schema.
  def test_lists_a_closed_set_of_values
    schema = infer([{ "status" => "active" }, { "status" => "passive" }])

    assert schema["status"].enum?
    assert_equal %w[active passive], schema["status"].listed_values
  end

  def test_free_text_is_shown_as_one_example_not_as_a_choice
    schema = infer([
      { "name" => "Ada Lovelace", "email" => "ada@example.com" },
      { "name" => "Grace Hopper", "email" => "grace@example.com" }
    ])

    refute schema["name"].enum?
    refute schema["email"].enum?
    assert_equal "Ada Lovelace", schema["name"].example
  end

  def test_a_repeated_value_marks_a_closed_set
    schema = infer([{ "role" => "Admin" }, { "role" => "Editor" }, { "role" => "Admin" }])

    assert schema["role"].enum?
  end

  # Response fixtures repeat by nature, so repetition proves nothing there:
  # only token-like values are listed as a set.
  def test_without_repetition_only_tokens_form_a_closed_set
    bodies = Array.new(3) { { "name" => "Stoneware Mug", "category" => "mugs" } } +
             Array.new(3) { { "name" => "Sencha", "category" => "tea" } }
    schema = Reqcord::Schema.infer(bodies, repetition: false)

    refute schema["name"].enum?
    assert schema["category"].enum?
    assert_equal %w[mugs tea], schema["category"].listed_values
  end

  # Two optional values among many requests is not repetition: the field was
  # only present twice, and each time it differed.
  def test_an_optional_field_with_all_distinct_values_is_not_a_choice
    payloads = [{ "destination" => "dubai-a91dde" }, { "destination" => "baska-54a058" }] + Array.new(8) { {} }

    refute infer(payloads)["destination"].enum?
  end

  def test_identifiers_are_never_a_choice
    schema = infer([
      { "experience_id" => "e-00056197", "option_id" => "35306" },
      { "experience_id" => "t14c2ec49", "option_id" => "35307" }
    ])

    refute schema["experience_id"].enum?
    refute schema["option_id"].enum?
  end

  def test_too_many_values_stop_being_a_choice
    payloads = (1..8).map { |index| { "code" => "c#{index}" } }

    refute infer(payloads)["code"].enum?
  end

  def test_listed_values_are_ordered_so_documentation_is_stable
    forward = infer([{ "status" => "active" }, { "status" => "passive" }])
    backward = infer([{ "status" => "passive" }, { "status" => "active" }])

    assert_equal forward["status"].listed_values, backward["status"].listed_values
  end

  def test_walks_arrays_and_nested_objects
    schema = infer([{ "tags" => %w[a b], "items" => [{ "sku" => "X1", "qty" => 2 }], "meta" => { "source" => "web" } }])

    assert_equal %w[tags[] items[].sku items[].qty meta.source], schema.map(&:path)
    assert_equal "integer", schema["items[].qty"].type
  end

  # A list response ([{...}, {...}]) has no key to hang its fields on.
  def test_top_level_arrays_are_described_with_an_index_path
    schema = infer([[{ "id" => 1, "name" => "Ada" }, { "id" => 2, "name" => "Linus" }]])

    assert_equal %w[[].id [].name], schema.map(&:path)
    assert_equal "integer", schema["[].id"].type
  end

  def test_a_field_with_two_types_reports_both
    schema = infer([{ "id" => 1 }, { "id" => "1" }])

    assert_equal "integer | string", schema["id"].type
  end

  def test_no_payload_means_no_schema
    assert_empty infer([])
    assert_empty infer([nil, {}])
  end
end
